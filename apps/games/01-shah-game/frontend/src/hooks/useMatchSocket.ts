import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { getSocket } from '@/lib/socket';
import { logger } from '@/lib/logger';
import { useGameStore } from '@/store/gameStore';
import { useMatchStore } from '@/store/matchStore';
import { useSessionStore } from '@/store/sessionStore';
import { type MatchState } from '@/types/match';
import type { GameStartedPayload } from '@/types/socket-events';

/**
 * Wires up Socket.IO listeners for the waiting-room events.
 *
 * NOTE: We do NOT call disconnectSocket() in cleanup here because React
 * StrictMode double-invokes effects in development, which would destroy the
 * socket on the first unmount and leave the player unsubscribed from the room.
 * The socket is disconnected explicitly in handleLeave (RoomPage) and logout.
 */
export function useMatchSocket(matchId: string | null): void {
  const token = useSessionStore((s) => s.token);
  const updatePlayers = useMatchStore((s) => s.updatePlayers);
  const setHost = useMatchStore((s) => s.setHost);
  const setMatch = useMatchStore((s) => s.setMatch);
  const setGameState = useGameStore((s) => s.setGameState);
  const navigate = useNavigate();

  useEffect(() => {
    if (!matchId || !token) return;

    const socket = getSocket(token);

    logger.debug(`[useMatchSocket] socket.connected=${socket.connected} for match ${matchId}`);

    /**
     * Connected (or reconnected) — emit match:subscribe ONLY here.
     *
     * Why not emit immediately above?  Socket.IO buffers events emitted
     * before the transport is open, so they arrive at the server before
     * handleConnection() finishes setting client.data.playerId.  Emitting
     * inside onConnect guarantees the server's connection handler has already
     * run and the playerId is set.
     */
    const onConnect = () => {
      logger.debug(`[useMatchSocket] Socket connected — subscribing to match ${matchId}`);
      socket.emit('match:subscribe', { matchId });
    };

    /** A player joined or left — server sends the full updated state */
    const onMatchUpdated = (state: MatchState) => {
      logger.debug(`[useMatchSocket] match:updated — players: ${state.players.map((p) => p.displayName).join(', ')}`);
      updatePlayers(state.players);
      setMatch(state);
    };

    /** Host changed — server sends the new host's playerId */
    const onHostChanged = ({ hostPlayerId }: { hostPlayerId: string }) => {
      logger.debug(`[useMatchSocket] match:host_changed → new host: ${hostPlayerId}`);
      setHost(hostPlayerId);
    };

    /** Host started the game */
    const onGameStarted = (payload: GameStartedPayload) => {
      logger.debug(
        `[useMatchSocket] game:started received — gameId: ${payload.gameId}, ` +
        `players: ${payload.gameState.players.map((p) => p.displayName).join(', ')}`,
      );
      setGameState(payload.gameState);
      logger.debug('[useMatchSocket] game:started — gameState set, navigating to /game/' + payload.matchId);
      void navigate(`/game/${payload.matchId}`, { replace: true });
    };

    socket.on('connect', onConnect);
    socket.on('match:updated', onMatchUpdated);
    socket.on('match:host_changed', onHostChanged);
    socket.on('game:started', onGameStarted);

    // If the socket is already connected (reused from a prior mount / page),
    // the 'connect' event will never fire again for this session.
    // Call onConnect() directly so we still emit match:subscribe.
    if (socket.connected) {
      logger.debug(`[useMatchSocket] Already connected — calling onConnect immediately`);
      onConnect();
    }

    return () => {
      logger.debug(`[useMatchSocket] Cleaning up listeners for match ${matchId}`);
      socket.off('connect', onConnect);
      socket.off('match:updated', onMatchUpdated);
      socket.off('match:host_changed', onHostChanged);
      socket.off('game:started', onGameStarted);
      // NOTE: do NOT call disconnectSocket() here — the socket must survive
      // navigation to GamePage. Disconnect is handled in handleLeave / logout.
    };
  }, [matchId, token, navigate, updatePlayers, setHost, setMatch, setGameState]);
}
