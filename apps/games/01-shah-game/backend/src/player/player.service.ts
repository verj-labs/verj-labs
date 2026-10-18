import { Injectable } from '@nestjs/common';
import { type MatchStatus, type Player } from '../../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface MatchHistoryItem {
  matchId: string;
  roomCode: string;
  playerCount: number;
  gamesPlayed: number;
  /** Best (lowest) finish rank the player achieved across all games in the match. */
  bestFinish: number | null;
  status: MatchStatus;
  createdAt: string;
}

export interface MatchHistoryPage {
  total: number;
  page: number;
  limit: number;
  items: MatchHistoryItem[];
}

// ─── Service ──────────────────────────────────────────────────────────────────

@Injectable()
export class PlayerService {
  constructor(private readonly prisma: PrismaService) {}

  async createPlayer(
    displayName: string,
    sessionToken: string,
  ): Promise<Player> {
    return this.prisma.player.create({
      data: { displayName, sessionToken },
    });
  }

  async findById(id: string): Promise<Player | null> {
    return this.prisma.player.findUnique({ where: { id } });
  }

  async findByToken(sessionToken: string): Promise<Player | null> {
    return this.prisma.player.findUnique({ where: { sessionToken } });
  }

  async getMatchHistory(
    playerId: string,
    page: number,
    limit: number,
  ): Promise<MatchHistoryPage> {
    const where = { matchPlayers: { some: { playerId } } };

    const [matches, total] = await Promise.all([
      this.prisma.match.findMany({
        where,
        include: {
          games: {
            include: { gameRankings: { where: { playerId } } },
          },
          _count: { select: { matchPlayers: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.match.count({ where }),
    ]);

    return {
      total,
      page,
      limit,
      items: matches.map((m) => ({
        matchId: m.id,
        roomCode: m.roomCode,
        playerCount: m._count.matchPlayers,
        gamesPlayed: m.games.length,
        bestFinish: m.games.reduce<number | null>((best, game) => {
          const rank = game.gameRankings[0]?.finishRank;
          if (rank === undefined) return best;
          return best === null ? rank : Math.min(best, rank);
        }, null),
        status: m.status,
        createdAt: m.createdAt.toISOString(),
      })),
    };
  }
}
