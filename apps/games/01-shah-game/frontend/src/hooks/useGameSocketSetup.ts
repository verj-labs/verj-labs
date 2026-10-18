/**
 * Sets up all Socket.IO listeners for in-game events.
 *
 * Mount this hook once inside `GamePage` (it subscribes on mount, cleans up
 * on unmount).  State is written directly to `useGameStore` so any component
 * can consume it without prop-drilling.
 */
import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { getSocket } from '@/lib/socket';
import { logger } from '@/lib/logger';
import { useGameStore } from '@/store/gameStore';
import { useMatchStore } from '@/store/matchStore';
import { useSessionStore } from '@/store/sessionStore';
import type {
  ExchangeSummaryPayload,
  GameFinishedPayload,
  GameStartedPayload,
  MatchFinishedPayload,
  PlayerDisconnectedPayload,
  PlayerFinishedPayload,
  PlayerReconnectedPayload,
  PileResetPayload,
  PlayerSkippedPayload,
  RoundEndedPayload,
  StateUpdatedPayload,
} from '@/types/socket-events';

export function useGameSocketSetup(matchId: string): void {
  const token = useSessionStore((s) => s.token);
  const playerId = useSessionStore((s) => s.player?.id);
  const {
    setGameState,
    setLocalPlayerId,
    setDisconnected,
    clearGame,
    showFinishedOverlay,
    showExchangeView,
    closeExchangeView,
    setSkippedPlayer,
    clearSkippedPlayer,
    setPileResetPending,
  } = useGameStore();
  const setMatchFinished = useMatchStore((s) => s.setMatchFinished);
  const navigate = useNavigate();

  useEffect(() => {
    if (!token || !playerId) return;

    const socket = getSocket(token);
    setLocalPlayerId(playerId);

    logger.debug(
      `[useGameSocketSetup] MOUNT — matchId: ${matchId}, ` +
      `socket.id: ${socket.id}, socket.connected: ${socket.connected}`,
    );

    // ── Named handlers (required so we can remove them precisely in cleanup) ─

    const handleReconnect = () => {
      logger.debug(`[useGameSocketSetup] socket reconnected — re-subscribing to match ${matchId}`);
      setDisconnected(false);
      socket.emit('match:subscribe', { matchId });
    };

    const handleGameStarted = (payload: GameStartedPayload) => {
      logger.debug(
        `[useGameSocketSetup] game:started — gameId: ${payload.gameId}, ` +
        `gameNumber: ${payload.gameState.gameNumber}, ` +
        `players: ${payload.gameState.players.map((p) => p.displayName).join(', ')}`,
      );
      setGameState(payload.gameState);
      closeExchangeView();
      toast.info(`Game #${payload.gameState.gameNumber} started!`);
    };

    const handleStateUpdated = (payload: StateUpdatedPayload) => {
      logger.debug(
        `[useGameSocketSetup] game:state_updated — round: ${payload.gameState.roundNumber}, ` +
        `activeIdx: ${payload.gameState.activePlayerIndex}`,
      );
      setGameState(payload.gameState);
    };

    const handleRoundEnded = (payload: RoundEndedPayload) => {
      logger.debug(
        `[useGameSocketSetup] game:round_ended — round ${payload.roundNumber}, ` +
        `winner: ${payload.winnerDisplayName ?? 'none'}`,
      );
      if (payload.winnerDisplayName) {
        toast.info(`Round ${payload.roundNumber} ended — ${payload.winnerDisplayName} won the pile.`);
      } else {
        toast.info(`Round ${payload.roundNumber} ended.`);
      }
    };

    const handlePileReset = (payload: PileResetPayload) => {
      logger.debug(`[useGameSocketSetup] game:pile_reset by ${payload.byDisplayName}`);
      setPileResetPending(true);
      // Clear after the scatter animation completes (~600ms)
      setTimeout(() => setPileResetPending(false), 700);
      toast.info(`Pile reset by ${payload.byDisplayName}!`);
    };

    const handlePlayerSkipped = (payload: PlayerSkippedPayload) => {
      logger.debug(`[useGameSocketSetup] game:player_skipped — ${payload.skippedDisplayName}`);
      setSkippedPlayer(payload.skippedPlayerId);
      // Clear after the flash animation (~500ms)
      setTimeout(() => clearSkippedPlayer(), 600);
      toast.info(`${payload.skippedDisplayName} was skipped.`);
    };

    const handlePlayerFinished = (payload: PlayerFinishedPayload) => {
      const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th'];
      const ordinal = ordinals[payload.finishRank - 1] ?? `${payload.finishRank}th`;
      logger.debug(`[useGameSocketSetup] game:player_finished — ${payload.displayName} (${ordinal})`);
      toast.success(`${payload.displayName} finished ${ordinal}!`);
    };

    const handleGameFinished = (payload: GameFinishedPayload) => {
      logger.debug(`[useGameSocketSetup] game:finished — showing overlay`);
      showFinishedOverlay(payload.rankings);
    };

    const handleExchange = (payload: ExchangeSummaryPayload) => {
      logger.debug(`[useGameSocketSetup] game:exchange — showing exchange view`);
      showExchangeView(payload);
    };

    const handleMatchFinished = (payload: MatchFinishedPayload) => {
      logger.debug(`[useGameSocketSetup] match:finished — navigating to results`);
      setMatchFinished(payload);
      void navigate(`/results/${payload.matchId}`, { replace: true });
    };

    const handlePlayerDisconnected = (payload: PlayerDisconnectedPayload) => {
      logger.debug(`[useGameSocketSetup] player:disconnected — ${payload.displayName}`);
      toast.warning(`${payload.displayName} disconnected.`);
    };

    const handlePlayerReconnected = (payload: PlayerReconnectedPayload) => {
      logger.debug(`[useGameSocketSetup] player:reconnected — ${payload.displayName}`);
      toast.success(`${payload.displayName} reconnected.`);
    };

    const handleDisconnect = () => {
      logger.debug(`[useGameSocketSetup] socket disconnected`);
      setDisconnected(true);
    };

    // ── Register all listeners before emitting subscribe ───────────────────

    socket.on('connect', handleReconnect);
    socket.on('game:started', handleGameStarted);
    socket.on('game:state_updated', handleStateUpdated);
    socket.on('game:round_ended', handleRoundEnded);
    socket.on('game:pile_reset', handlePileReset);
    socket.on('game:player_skipped', handlePlayerSkipped);
    socket.on('game:player_finished', handlePlayerFinished);
    socket.on('game:finished', handleGameFinished);
    socket.on('game:exchange', handleExchange);
    socket.on('match:finished', handleMatchFinished);
    socket.on('player:disconnected', handlePlayerDisconnected);
    socket.on('player:reconnected', handlePlayerReconnected);
    socket.on('disconnect', handleDisconnect);

    // Subscribe to the match room AFTER all listeners are registered.
    // The server sends game:state_updated as a catch-up if a game is in progress.
    logger.debug(
      `[useGameSocketSetup] Emitting match:subscribe for match ${matchId} ` +
      `(socket.connected=${socket.connected})`,
    );
    socket.emit('match:subscribe', { matchId });

    // If the socket reconnects in the future, handleReconnect will re-subscribe.
    // If it is already connected but connect won't fire again, the emit above covers it.

    return () => {
      logger.debug(`[useGameSocketSetup] CLEANUP — removing listeners for match ${matchId}`);
      socket.off('connect', handleReconnect);
      socket.off('game:started', handleGameStarted);
      socket.off('game:state_updated', handleStateUpdated);
      socket.off('game:round_ended', handleRoundEnded);
      socket.off('game:pile_reset', handlePileReset);
      socket.off('game:player_skipped', handlePlayerSkipped);
      socket.off('game:player_finished', handlePlayerFinished);
      socket.off('game:finished', handleGameFinished);
      socket.off('game:exchange', handleExchange);
      socket.off('match:finished', handleMatchFinished);
      socket.off('player:disconnected', handlePlayerDisconnected);
      socket.off('player:reconnected', handlePlayerReconnected);
      socket.off('disconnect', handleDisconnect);
      clearGame();
    };
  }, [matchId, token, playerId, setGameState, setLocalPlayerId, setDisconnected, clearGame, showFinishedOverlay, showExchangeView, closeExchangeView, setMatchFinished, navigate, setSkippedPlayer, clearSkippedPlayer, setPileResetPending]);
}
