import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { SeatSlot } from '@/components/ui/SeatSlot';
import { useMatchSocket } from '@/hooks/useMatchSocket';
import { logger } from '@/lib/logger';
import { disconnectSocket } from '@/lib/socket';
import { getMatch, leaveMatch, startMatch } from '@/services/match.service';
import { useGameStore } from '@/store/gameStore';
import { useMatchStore } from '@/store/matchStore';
import { useSessionStore } from '@/store/sessionStore';
import { type MatchPlayerInfo } from '@/types/match';
import { COPY } from '@/lib/copy';

const MAX_SEATS = 8;
const MIN_TO_START = 3;

// ─── Main page ───────────────────────────────────────────────────────────────

export default function RoomPage() {
  const { code } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const player = useSessionStore((s) => s.player);
  const matchId = useMatchStore((s) => s.matchId);
  const roomCode = useMatchStore((s) => s.roomCode);
  const hostPlayerId = useMatchStore((s) => s.hostPlayerId);
  const players = useMatchStore((s) => s.players);
  const status = useMatchStore((s) => s.status);
  const setMatch = useMatchStore((s) => s.setMatch);

  // Watch for game state arriving via game:started socket event.
  // When onGameStarted (useMatchSocket) fires it calls setGameState + navigate.
  // This useEffect is a fallback watchdog: if React unmounts RoomPage before
  // the socket event fires, navigation is handled here instead.
  const gameState = useGameStore((s) => s.gameState);
  useEffect(() => {
    if (gameState && matchId) {
      logger.debug('[RoomPage] gameState set in store — navigating to /game/' + matchId);
      void navigate(`/game/${matchId}`, { replace: true });
    }
  }, [gameState, matchId, navigate]);

  const [fetchError, setFetchError] = useState<string | null>(null);
  const [startError, setStartError] = useState<string | null>(null);
  const [isStarting, setIsStarting] = useState(false);
  const [isLeaving, setIsLeaving] = useState(false);
  const [isFetching, setIsFetching] = useState(false);
  const [copied, setCopied] = useState(false);

  // ─── If no matchId in store, redirect ──────────────────────────────────

  useEffect(() => {
    if (!matchId) {
      void navigate('/lobby', { replace: true });
    }
  }, [matchId, navigate]);

  // ─── Fetch current match state on mount ────────────────────────────────

  useEffect(() => {
    if (!matchId) return;
    setIsFetching(true);
    getMatch(matchId)
      .then(setMatch)
      .catch(() => setFetchError('Failed to load room. Please try again.'))
      .finally(() => setIsFetching(false));
  }, [matchId, setMatch]);

  // ─── Wire socket for real-time updates ─────────────────────────────────

  useMatchSocket(matchId);

  // ─── Derived values ─────────────────────────────────────────────────────

  const currentPlayerId = player?.id ?? null;
  const isHost = currentPlayerId === hostPlayerId;
  const playerCount = players.length;
  const canStart = isHost && playerCount >= MIN_TO_START;

  const displayCode = roomCode ?? code ?? '????';

  // Build seat array: fill from index 0 to MAX_SEATS-1
  const seats: (MatchPlayerInfo | null)[] = Array.from(
    { length: MAX_SEATS },
    (_, i) => players.find((p) => p.seatIndex === i) ?? null,
  );

  // ─── Handlers ───────────────────────────────────────────────────────────

  async function handleCopy(): Promise<void> {
    try {
      await navigator.clipboard.writeText(displayCode);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Clipboard unavailable — ignore silently
    }
  }

  async function handleStart(): Promise<void> {
    if (!matchId || !canStart) return;
    setStartError(null);
    setIsStarting(true);
    try {
      const updated = await startMatch(matchId);
      logger.debug('[RoomPage] handleStart REST response received — status:', updated.status);
      setMatch(updated);
      // Do NOT navigate here. Navigation is driven solely by the `game:started`
      // socket event (handled in useMatchSocket → onGameStarted). This ensures
      // gameState is set via the socket payload BEFORE we leave this page, so
      // GamePage never mounts with a null gameState.
      // All other players also navigate via game:started, so this keeps everyone
      // on the same code path.
      logger.debug('[RoomPage] handleStart — waiting for game:started socket event to navigate');
    } catch {
      setStartError('Failed to start game. Please try again.');
    } finally {
      setIsStarting(false);
    }
  }

  async function handleLeave(): Promise<void> {
    if (!matchId) return;
    setIsLeaving(true);
    try {
      await leaveMatch(matchId);
    } catch {
      // Best-effort — still navigate away
    } finally {
      setIsLeaving(false);
      // Disconnect the socket before navigating back to lobby so we don't
      // stay subscribed to this match room during the next session.
      disconnectSocket();
      void navigate('/lobby', { replace: true });
    }
  }

  // ─── Render ──────────────────────────────────────────────────────────────

  if (isFetching) {
    return (
      <div className="min-h-screen bg-[var(--color-bg-0)] flex items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  if (fetchError) {
    return (
      <div className="min-h-screen bg-[var(--color-bg-0)] flex flex-col items-center justify-center gap-4">
        <p className="text-[var(--color-danger-red)] text-sm" role="alert">
          {fetchError}
        </p>
        <Button
          variant="ghost"
          onClick={() => void navigate('/lobby', { replace: true })}
        >
          {COPY.backToLobby}
        </Button>
      </div>
    );
  }

  return (
    <main className="min-h-screen bg-[var(--color-bg-0)] flex flex-col items-center justify-center gap-6 p-4">
      {/* Room code display */}
      <div className="text-center space-y-2">
        <p className="text-[var(--color-text-muted)] text-xs uppercase tracking-widest">
          {COPY.roomCodeLabel}
        </p>
        <div className="flex items-center gap-3 justify-center">
          <span
            data-testid="room-code"
            className="text-5xl font-bold text-[var(--color-electric-yellow)] tracking-[0.25em] select-all"
            style={{ fontFamily: 'var(--font-heading)' }}
            aria-label={`Room code: ${displayCode}`}
          >
            {displayCode}
          </span>
          <button
            onClick={() => void handleCopy()}
            title={copied ? 'Copied!' : 'Copy room code'}
            aria-label={copied ? 'Copied!' : 'Copy room code'}
            className="text-[var(--color-text-muted)] hover:text-[var(--color-text-primary)] transition text-xl leading-none"
          >
            {copied ? '✓' : '📋'}
          </button>
        </div>
        <p data-testid="player-count" className="text-[var(--color-text-muted)] text-sm">
          {playerCount}/{MAX_SEATS} players joined
        </p>
      </div>

      {/* Seat grid */}
      <div className="w-full max-w-md grid grid-cols-4 gap-3">
        {seats.map((seat, idx) => (
          <SeatSlot
            key={idx}
            seat={seat}
            seatIndex={idx}
            isCurrentPlayer={seat?.playerId === currentPlayerId}
            isHost={seat?.playerId === hostPlayerId}
          />
        ))}
      </div>

      {/* Status & controls */}
      <div className="w-full max-w-md space-y-3">
        {status === 'lobby' &&
          (isHost ? (
            <>
              {startError && (
                <p role="alert" className="text-red-300 text-xs text-center">
                  {startError}
                </p>
              )}
              <Button
                onClick={() => void handleStart()}
                disabled={!canStart || isStarting}
                data-testid="start-game-button"
                variant="cta"
                size="lg"
                title={
                  !canStart
                    ? COPY.waitingForPlayers(MIN_TO_START - playerCount)
                    : undefined
                }
                className="w-full disabled:opacity-40"
                aria-label="Start game"
              >
                {isStarting ? (
                  <span className="flex items-center gap-2 justify-center">
                    <LoadingSpinner size="sm" color="text-[var(--color-bg-0)]" />
                    Starting…
                  </span>
                ) : !canStart ? (
                  COPY.waitingForPlayers(MIN_TO_START - playerCount)
                ) : (
                  COPY.startGame
                )}
              </Button>
            </>
          ) : (
            <p className="text-[var(--color-text-muted)] text-sm text-center">
              {COPY.waitingForHost}
            </p>
          ))}

        <Button
          onClick={() => void handleLeave()}
          disabled={isLeaving}
          variant="ghost"
          className="w-full"
          aria-label="Leave room"
        >
          {isLeaving ? (
            <span className="flex items-center gap-2 justify-center">
              <LoadingSpinner size="sm" />
              Leaving…
            </span>
          ) : (
            'Leave'
          )}
        </Button>
      </div>
    </main>
  );
}
