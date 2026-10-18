import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { type MatchStatus } from '../../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { REDIS_CLIENT } from '../redis/redis.constants';
import {
  type MatchPlayerInfo,
  type MatchState,
} from '../shared/types/match.types';
import {
  type MatchFinishedPayload,
  type PlayerMatchStat,
} from '../shared/types/socket-payloads.types';
import Redis from 'ioredis';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface MatchSummary {
  matchId: string;
  roomCode: string;
  status: string;
  createdAt: string;
  endedAt: string | null;
  players: Array<{ id: string; displayName: string; seatIndex: number }>;
  aggregate: PlayerMatchStat[];
  games: Array<{
    gameId: string;
    gameNumber: number;
    direction: string;
    status: string;
    startedAt: string | null;
    endedAt: string | null;
    rankings: Array<{ playerId: string; displayName: string; rank: number }>;
  }>;
}

/** Characters valid in room codes — excludes 0, 1, O, I to avoid confusion */
const ROOM_CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const ROOM_CODE_LENGTH = 4;
const MAX_RETRIES = 5;
const MAX_PLAYERS = 8;
const MIN_PLAYERS_TO_START = 3;
const MATCH_STATE_TTL_SECONDS = 86_400; // 24 h
const REDIS_CLEANUP_DELAY_MS = 60 * 60 * 1_000; // 60 min

@Injectable()
export class MatchService {
  private readonly logger = new Logger(MatchService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  // ─── Code Generation ────────────────────────────────────────────────────────

  generateRoomCode(): string {
    return Array.from(
      { length: ROOM_CODE_LENGTH },
      () => ROOM_CODE_CHARS[Math.floor(Math.random() * ROOM_CODE_CHARS.length)],
    ).join('');
  }

  // ─── Stale-match guard ───────────────────────────────────────────────────────

  /**
   * Checks whether the given player is still a member of a non-finished match.
   *
   * - lobby  → stale abandoned session; auto-removed so the player can proceed.
   * - in_progress → throws 409 ConflictException with the matchId embedded in
   *   the response body so the client can offer a "Rejoin" link.
   *
   * @param playerId      The player to check.
   * @param excludeMatchId  Optional match to skip (the match being joined, to
   *                        avoid flagging existing membership as a conflict).
   */
  private async resolveStaleMatch(
    playerId: string,
    excludeMatchId?: string,
  ): Promise<void> {
    const staleEntry = await this.prisma.matchPlayer.findFirst({
      where: {
        playerId,
        match: {
          status: { not: 'finished' as MatchStatus },
          ...(excludeMatchId ? { id: { not: excludeMatchId } } : {}),
        },
      },
      include: { match: true },
    });

    if (!staleEntry) return;

    if (staleEntry.match.status === 'lobby') {
      // Stale lobby membership (e.g. previous session abandoned) — auto-clean
      this.logger.warn(
        `Player ${playerId} has stale lobby membership in match ${staleEntry.matchId}. Auto-removing.`,
      );
      await this.prisma.$transaction([
        this.prisma.matchPlayer.delete({
          where: {
            matchId_playerId: { matchId: staleEntry.matchId, playerId },
          },
        }),
        this.prisma.match.update({
          where: { id: staleEntry.matchId },
          data: { playerCount: { decrement: 1 } },
        }),
      ]);
      await this.redis.del(`match:${staleEntry.matchId}:state`);
    } else {
      // in_progress — player has an active game they should rejoin
      throw new ConflictException({
        message:
          'You have an active game in progress. Please rejoin that game or wait for it to finish.',
        matchId: staleEntry.matchId,
      });
    }
  }

  // ─── Create ─────────────────────────────────────────────────────────────────

  async createMatch(
    hostPlayerId: string,
    hostDisplayName: string,
  ): Promise<MatchState> {
    let roomCode = '';
    let attempt = 0;

    while (attempt < MAX_RETRIES) {
      roomCode = this.generateRoomCode();
      const exists = await this.prisma.match.findUnique({
        where: { roomCode },
      });
      if (!exists) break;
      attempt++;
    }

    if (attempt === MAX_RETRIES) {
      throw new ConflictException(
        'Could not generate a unique room code. Try again.',
      );
    }

    await this.resolveStaleMatch(hostPlayerId);

    const match = await this.prisma.match.create({
      data: {
        roomCode,
        hostPlayerId,
        playerCount: 1,
        status: 'lobby',
        matchPlayers: {
          create: { playerId: hostPlayerId, seatIndex: 0 },
        },
      },
    });

    const state = this.buildState(
      match,
      [{ playerId: hostPlayerId, displayName: hostDisplayName, seatIndex: 0 }],
      'lobby',
    );

    await this.saveMatchState(state);
    this.logger.log(`Match created: ${match.id} code=${roomCode}`);
    return state;
  }

  // ─── Join ────────────────────────────────────────────────────────────────────

  async joinMatch(
    roomCode: string,
    playerId: string,
    _displayName: string,
  ): Promise<MatchState> {
    const match = await this.prisma.match.findUnique({
      where: { roomCode },
      include: {
        matchPlayers: {
          include: { player: true },
          orderBy: { seatIndex: 'asc' },
        },
      },
    });

    if (!match) {
      throw new NotFoundException(`Room '${roomCode}' does not exist.`);
    }
    if (match.status !== 'lobby') {
      throw new ConflictException(
        'This match has already started or finished.',
      );
    }
    if (match.playerCount >= MAX_PLAYERS) {
      throw new ConflictException('This room is full.');
    }

    const alreadyIn = match.matchPlayers.some((mp) => mp.playerId === playerId);
    if (alreadyIn) {
      // Already in this room — just return the current state so the client can
      // navigate to it (handles page refresh / double-click)
      this.logger.log(
        `Player ${playerId} is already in match ${match.id} — returning current state`,
      );
      return this.buildState(
        match,
        this.mapPlayers(match.matchPlayers),
        'lobby',
      );
    }

    await this.resolveStaleMatch(playerId, match.id);

    // Use an interactive transaction with SELECT … FOR UPDATE on the match row
    // so concurrent joins are serialised. Without this lock, parallel requests
    // all read the same playerCount, assign the same seatIndex, and the last
    // saveMatchState call overwrites the others (TOCTOU race condition).
    const { allPlayers } = await this.prisma.$transaction(async (tx) => {
      const [locked] = await tx.$queryRaw<Array<{ player_count: number }>>`
          SELECT player_count FROM matches WHERE id = ${match.id}::uuid FOR UPDATE
        `;
      const seatIndex = locked.player_count;
      await tx.matchPlayer.create({
        data: { matchId: match.id, playerId, seatIndex },
      });
      await tx.match.update({
        where: { id: match.id },
        data: { playerCount: { increment: 1 } },
      });
      const allPlayers = await tx.matchPlayer.findMany({
        where: { matchId: match.id },
        include: { player: true },
        orderBy: { seatIndex: 'asc' },
      });
      return { seatIndex, allPlayers };
    });

    const updatedState = this.buildState(
      match,
      this.mapPlayers(allPlayers),
      'lobby',
    );

    await this.saveMatchState(updatedState);
    this.logger.log(`Player ${playerId} joined match ${match.id}`);
    return updatedState;
  }

  // ─── Leave ───────────────────────────────────────────────────────────────────

  async leaveMatch(
    matchId: string,
    playerId: string,
  ): Promise<{ matchEnded: boolean; payload?: MatchFinishedPayload }> {
    const match = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        matchPlayers: {
          include: { player: true },
          orderBy: { seatIndex: 'asc' },
        },
      },
    });

    if (!match) {
      throw new NotFoundException('Match not found.');
    }

    if (match.status === 'finished') {
      throw new ConflictException('Match is already finished.');
    }

    if (!match.matchPlayers.some((mp) => mp.playerId === playerId)) {
      throw new NotFoundException('You are not in this match.');
    }

    const remainingPlayers = match.matchPlayers.filter(
      (mp) => mp.playerId !== playerId,
    );

    // Last player — delete or finish the match
    if (remainingPlayers.length === 0) {
      if (match.status === 'lobby') {
        await this.prisma.$transaction([
          this.prisma.matchPlayer.deleteMany({ where: { matchId } }),
          this.prisma.match.delete({ where: { id: matchId } }),
        ]);
      } else {
        await this.prisma.$transaction([
          this.prisma.matchPlayer.deleteMany({ where: { matchId } }),
          this.prisma.match.update({
            where: { id: matchId },
            data: { status: 'finished', endedAt: new Date() },
          }),
        ]);
      }
      await this.redis.del(`match:${matchId}:state`);
      await this.redis.del(`game:reconnect:${playerId}`);
      this.logger.log(`Match ${matchId} ended (last player left)`);
      return { matchEnded: true };
    }

    const newHostId =
      match.hostPlayerId === playerId
        ? remainingPlayers[0].playerId
        : match.hostPlayerId;

    if (match.status === 'lobby') {
      // Lobby leave — existing behaviour
      await this.prisma.$transaction([
        this.prisma.matchPlayer.delete({
          where: { matchId_playerId: { matchId, playerId } },
        }),
        this.prisma.match.update({
          where: { id: matchId },
          data: { playerCount: { decrement: 1 }, hostPlayerId: newHostId },
        }),
      ]);

      const updatedState = this.buildState(
        { ...match, hostPlayerId: newHostId },
        this.mapPlayers(remainingPlayers),
      );
      await this.saveMatchState(updatedState);
      this.logger.log(`Player ${playerId} left match ${matchId}`);
      return { matchEnded: false };
    }

    // in_progress forfeit — too few players left to continue
    if (remainingPlayers.length < MIN_PLAYERS_TO_START) {
      const payload = await this._abandonInProgressMatch(
        matchId,
        match,
        playerId,
      );
      return { matchEnded: true, payload };
    }

    // in_progress forfeit — enough players remain
    await this.prisma.$transaction([
      this.prisma.matchPlayer.delete({
        where: { matchId_playerId: { matchId, playerId } },
      }),
      this.prisma.match.update({
        where: { id: matchId },
        data: { playerCount: { decrement: 1 }, hostPlayerId: newHostId },
      }),
    ]);

    await this.redis.del(`game:reconnect:${playerId}`);
    const updatedState = this.buildState(
      { ...match, hostPlayerId: newHostId },
      this.mapPlayers(remainingPlayers),
      'in_progress',
    );
    await this.saveMatchState(updatedState);
    this.logger.log(
      `Player ${playerId} forfeited match ${matchId} (${remainingPlayers.length} players remaining)`,
    );
    return { matchEnded: false };
  }

  private async _abandonInProgressMatch(
    matchId: string,
    match: {
      hostPlayerId: string;
      matchPlayers: Array<{
        playerId: string;
        seatIndex: number;
        player: { displayName: string };
      }>;
    },
    leavingPlayerId: string,
  ): Promise<MatchFinishedPayload> {
    await this.prisma.$transaction([
      this.prisma.matchPlayer.delete({
        where: { matchId_playerId: { matchId, playerId: leavingPlayerId } },
      }),
      this.prisma.match.update({
        where: { id: matchId },
        data: { status: 'finished', endedAt: new Date(), playerCount: { decrement: 1 } },
      }),
    ]);

    await this.redis.del(`match:${matchId}:state`);
    await this.redis.del(`game:reconnect:${leavingPlayerId}`);

    const matchWithGames = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        matchPlayers: { include: { player: true } },
        games: {
          where: { status: 'finished' },
          include: { gameRankings: { include: { player: true } } },
          orderBy: { gameNumber: 'asc' },
        },
      },
    });

    if (!matchWithGames) {
      return { matchId, totalGames: 0, standings: [] };
    }

    const statMap = new Map<string, PlayerMatchStat>();
    // Include all original players (including the one leaving)
    for (const mp of match.matchPlayers) {
      statMap.set(mp.playerId, {
        playerId: mp.playerId,
        displayName: mp.player.displayName,
        gamesPlayed: 0,
        wins: 0,
        averageRank: 0,
        bestFinish: Infinity,
      });
    }

    for (const game of matchWithGames.games) {
      for (const ranking of game.gameRankings) {
        const stat = statMap.get(ranking.playerId);
        if (!stat) continue;
        stat.gamesPlayed++;
        if (ranking.finishRank === 1) stat.wins++;
        stat.averageRank += ranking.finishRank;
        if (ranking.finishRank < stat.bestFinish)
          stat.bestFinish = ranking.finishRank;
      }
    }

    const standings: PlayerMatchStat[] = [...statMap.values()]
      .map((s) => ({
        ...s,
        averageRank:
          s.gamesPlayed > 0
            ? Math.round((s.averageRank / s.gamesPlayed) * 100) / 100
            : 0,
        bestFinish: s.bestFinish === Infinity ? 0 : s.bestFinish,
      }))
      .sort((a, b) => a.averageRank - b.averageRank);

    this.logger.log(
      `Match ${matchId} abandoned by player ${leavingPlayerId} (too few players)`,
    );
    return { matchId, totalGames: matchWithGames.games.length, standings };
  }

  // ─── Start ───────────────────────────────────────────────────────────────────

  async startMatch(
    matchId: string,
    requestingPlayerId: string,
  ): Promise<MatchState> {
    const match = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        matchPlayers: {
          include: { player: true },
          orderBy: { seatIndex: 'asc' },
        },
      },
    });

    if (!match) {
      throw new NotFoundException('Match not found.');
    }
    if (match.status !== 'lobby') {
      throw new ConflictException(
        'This match has already started or finished.',
      );
    }
    if (match.hostPlayerId !== requestingPlayerId) {
      throw new ForbiddenException('Only the host can start the match.');
    }
    if (match.playerCount < MIN_PLAYERS_TO_START) {
      throw new ConflictException(
        `Need at least ${MIN_PLAYERS_TO_START} players to start.`,
      );
    }

    await this.prisma.match.update({
      where: { id: matchId },
      data: { status: 'in_progress', startedAt: new Date() },
    });

    const updatedState = this.buildState(
      match,
      this.mapPlayers(match.matchPlayers),
      'in_progress',
    );

    await this.saveMatchState(updatedState);
    this.logger.log(`Match ${matchId} started`);
    return updatedState;
  }

  // ─── End match ───────────────────────────────────────────────────────────────

  async endMatch(
    matchId: string,
    requestingPlayerId: string,
  ): Promise<MatchFinishedPayload> {
    const match = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        matchPlayers: { include: { player: true } },
        games: {
          where: { status: 'finished' },
          include: {
            gameRankings: { include: { player: true } },
          },
          orderBy: { gameNumber: 'asc' },
        },
      },
    });

    if (!match) throw new NotFoundException('Match not found.');
    if (match.status === 'finished')
      throw new ConflictException('Match is already finished.');
    if (match.hostPlayerId !== requestingPlayerId)
      throw new ForbiddenException('Only the host can end the match.');

    const endedAt = new Date();
    await this.prisma.match.update({
      where: { id: matchId },
      data: { status: 'finished', endedAt },
    });

    // Compute aggregate stats per player across all finished games
    const statMap = new Map<string, PlayerMatchStat>();
    for (const mp of match.matchPlayers) {
      statMap.set(mp.playerId, {
        playerId: mp.playerId,
        displayName: mp.player.displayName,
        gamesPlayed: 0,
        wins: 0,
        averageRank: 0,
        bestFinish: Infinity,
      });
    }

    for (const game of match.games) {
      for (const ranking of game.gameRankings) {
        const stat = statMap.get(ranking.playerId);
        if (!stat) continue;
        stat.gamesPlayed++;
        if (ranking.finishRank === 1) stat.wins++;
        // Running sum — we'll divide to get average below
        stat.averageRank += ranking.finishRank;
        if (ranking.finishRank < stat.bestFinish) {
          stat.bestFinish = ranking.finishRank;
        }
      }
    }

    const standings: PlayerMatchStat[] = [...statMap.values()]
      .map((s) => ({
        ...s,
        averageRank:
          s.gamesPlayed > 0
            ? Math.round((s.averageRank / s.gamesPlayed) * 100) / 100
            : 0,
        bestFinish: s.bestFinish === Infinity ? 0 : s.bestFinish,
      }))
      .sort((a, b) => a.averageRank - b.averageRank);

    // Schedule Redis cleanup after 60 minutes
    const gameIds = match.games.map((g) => g.id);
    setTimeout(() => {
      void this.cleanupRedisKeys(matchId, gameIds);
    }, REDIS_CLEANUP_DELAY_MS);

    this.logger.log(
      `Match ${matchId} ended. ${match.games.length} games played.`,
    );

    return {
      matchId,
      totalGames: match.games.length,
      standings,
    };
  }

  // ─── Match summary ────────────────────────────────────────────────────────────

  async getMatchSummary(
    matchId: string,
    requestingPlayerId: string,
  ): Promise<MatchSummary> {
    const match = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        matchPlayers: {
          include: { player: true },
          orderBy: { seatIndex: 'asc' },
        },
        games: {
          include: {
            gameRankings: { include: { player: true } },
          },
          orderBy: { gameNumber: 'asc' },
        },
      },
    });

    if (!match) throw new NotFoundException('Match not found.');

    const isParticipant = match.matchPlayers.some(
      (mp) => mp.playerId === requestingPlayerId,
    );
    if (!isParticipant)
      throw new ForbiddenException('You did not participate in this match.');

    // Aggregate stats
    const statMap = new Map<string, PlayerMatchStat>();
    for (const mp of match.matchPlayers) {
      statMap.set(mp.playerId, {
        playerId: mp.playerId,
        displayName: mp.player.displayName,
        gamesPlayed: 0,
        wins: 0,
        averageRank: 0,
        bestFinish: Infinity,
      });
    }

    const games = match.games
      .filter((g) => g.status === 'finished')
      .map((game) => {
        const rankings = game.gameRankings
          .sort((a, b) => a.finishRank - b.finishRank)
          .map((r) => ({
            playerId: r.playerId,
            displayName: r.player.displayName,
            rank: r.finishRank,
          }));

        for (const r of game.gameRankings) {
          const stat = statMap.get(r.playerId);
          if (!stat) continue;
          stat.gamesPlayed++;
          if (r.finishRank === 1) stat.wins++;
          stat.averageRank += r.finishRank;
          if (r.finishRank < stat.bestFinish) stat.bestFinish = r.finishRank;
        }

        return {
          gameId: game.id,
          gameNumber: game.gameNumber,
          direction: game.direction,
          status: game.status,
          startedAt: game.startedAt?.toISOString() ?? null,
          endedAt: game.endedAt?.toISOString() ?? null,
          rankings,
        };
      });

    const aggregate: PlayerMatchStat[] = [...statMap.values()]
      .map((s) => ({
        ...s,
        averageRank:
          s.gamesPlayed > 0
            ? Math.round((s.averageRank / s.gamesPlayed) * 100) / 100
            : 0,
        bestFinish: s.bestFinish === Infinity ? 0 : s.bestFinish,
      }))
      .sort((a, b) => a.averageRank - b.averageRank);

    return {
      matchId: match.id,
      roomCode: match.roomCode,
      status: match.status,
      createdAt: match.createdAt.toISOString(),
      endedAt: match.endedAt?.toISOString() ?? null,
      players: match.matchPlayers.map((mp) => ({
        id: mp.playerId,
        displayName: mp.player.displayName,
        seatIndex: mp.seatIndex,
      })),
      aggregate,
      games,
    };
  }

  // ─── Get ─────────────────────────────────────────────────────────────────────

  async getMatch(matchId: string): Promise<MatchState> {
    let cached: string | null = null;
    try {
      cached = await this.redis.get(`match:${matchId}:state`);
    } catch (err) {
      // Redis read failure — fall through to the database
      this.logger.warn(
        `Redis read failed in getMatch (${matchId}): ${String(err)}`,
      );
    }

    if (cached) {
      return JSON.parse(cached) as MatchState;
    }

    const match = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        matchPlayers: {
          include: { player: true },
          orderBy: { seatIndex: 'asc' },
        },
      },
    });

    if (!match) {
      throw new NotFoundException('Match not found.');
    }

    const state = this.buildState(match, this.mapPlayers(match.matchPlayers));

    await this.saveMatchState(state);
    return state;
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  private mapPlayers(
    matchPlayers: Array<{
      playerId: string;
      seatIndex: number;
      player: { displayName: string };
    }>,
  ): MatchPlayerInfo[] {
    return matchPlayers.map((mp) => ({
      playerId: mp.playerId,
      displayName: mp.player.displayName,
      seatIndex: mp.seatIndex,
    }));
  }

  private buildState(
    match: {
      id: string;
      roomCode: string;
      hostPlayerId: string;
      status: MatchStatus;
      playerCount: number;
    },
    players: MatchPlayerInfo[],
    status?: MatchState['status'],
  ): MatchState {
    return {
      id: match.id,
      roomCode: match.roomCode,
      hostPlayerId: match.hostPlayerId,
      status: status ?? (match.status as MatchState['status']),
      players,
      playerCount: players.length,
    };
  }

  private async cleanupRedisKeys(
    matchId: string,
    gameIds: string[],
  ): Promise<void> {
    const keys = [
      `match:${matchId}:state`,
      ...gameIds.flatMap((id) => [`game:${id}:state`, `game:${id}:hand:*`]),
    ];
    try {
      // Delete known keys; scan-based wildcard keys handled individually
      const exactKeys = keys.filter((k) => !k.includes('*'));
      if (exactKeys.length) await this.redis.del(...exactKeys);

      // Scan for per-player hand keys (game:<id>:hand:<playerId>)
      for (const gameId of gameIds) {
        const pattern = `game:${gameId}:hand:*`;
        let cursor = '0';
        do {
          const [nextCursor, found] = await this.redis.scan(
            cursor,
            'MATCH',
            pattern,
            'COUNT',
            100,
          );
          cursor = nextCursor;
          if (found.length) await this.redis.del(...found);
        } while (cursor !== '0');
      }

      this.logger.log(
        `Redis cleanup complete for match ${matchId} (${gameIds.length} games)`,
      );
    } catch (err) {
      this.logger.error(
        `Redis cleanup failed for match ${matchId}: ${String(err)}`,
      );
    }
  }

  private async saveMatchState(state: MatchState): Promise<void> {
    try {
      await this.redis.set(
        `match:${state.id}:state`,
        JSON.stringify(state),
        'EX',
        MATCH_STATE_TTL_SECONDS,
      );
    } catch (err) {
      this.logger.error(
        `Redis write failed in saveMatchState (${state.id}): ${String(err)}`,
      );
      throw new InternalServerErrorException(
        'Match state storage is currently unavailable.',
      );
    }
  }
}
