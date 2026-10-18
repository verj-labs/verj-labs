import { type AxiosError } from 'axios';
import { type ChangeEvent, type FormEvent, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { createMatch, joinMatch } from '@/services/match.service';
import { useMatchStore } from '@/store/matchStore';
import { useSessionStore } from '@/store/sessionStore';
import { COPY } from '@/lib/copy';

const ROOM_CODE_LENGTH = 4;

interface ParsedError {
  message: string;
  /** matchId to rejoin if this is an active-game 409 */
  rejoinMatchId?: string;
}

function parseJoinError(error: unknown): ParsedError {
  const status = (error as AxiosError)?.response?.status;
  if (status === 404) return { message: COPY.roomNotFound };
  if (status === 409) {
    const data = (error as AxiosError)?.response?.data as {
      message?: string;
      matchId?: string;
    };
    const message = data?.message?.toLowerCase() ?? '';
    if (message.includes('full')) return { message: COPY.roomFull };
    if (message.includes('already started') || message.includes('finished'))
      return { message: COPY.gameAlreadyStarted };
    if (message.includes('already in this room'))
      return { message: COPY.alreadyInRoom };
    if (
      message.includes('another') ||
      message.includes('active room') ||
      message.includes('active game')
    )
      return {
        message: 'You have an active game in progress.',
        rejoinMatchId: data?.matchId,
      };
    return { message: COPY.genericError };
  }
  return { message: COPY.genericError };
}

export default function LobbyPage() {
  const navigate = useNavigate();
  const player = useSessionStore((s) => s.player);
  const { setMatch, setLoading } = useMatchStore();

  const [roomCode, setRoomCode] = useState('');
  const [createError, setCreateError] = useState<string | null>(null);
  const [joinError, setJoinError] = useState<string | null>(null);
  const [rejoinMatchId, setRejoinMatchId] = useState<string | null>(null);
  const [joinLoading, setJoinLoading] = useState(false);
  const [createLoading, setCreateLoading] = useState(false);

  // ─── Create room ──────────────────────────────────────────────────────────

  async function handleCreate(): Promise<void> {
    setCreateError(null);
    setRejoinMatchId(null);
    setCreateLoading(true);
    setLoading(true);
    try {
      const { match, roomCode: code } = await createMatch();
      setMatch(match);
      void navigate(`/room/${code}`);
    } catch (err) {
      const { message, rejoinMatchId: mid } = parseJoinError(err);
      setCreateError(message);
      if (mid) setRejoinMatchId(mid);
    } finally {
      setCreateLoading(false);
      setLoading(false);
    }
  }

  // ─── Join room ────────────────────────────────────────────────────────────

  function handleCodeChange(e: ChangeEvent<HTMLInputElement>): void {
    const upper = e.target.value.toUpperCase().replace(/[^A-Z2-9]/g, '');
    setRoomCode(upper.slice(0, ROOM_CODE_LENGTH));
    if (joinError) setJoinError(null);
    if (rejoinMatchId) setRejoinMatchId(null);
  }

  async function handleJoin(e: FormEvent): Promise<void> {
    e.preventDefault();
    if (roomCode.length !== ROOM_CODE_LENGTH) return;
    setJoinError(null);
    setRejoinMatchId(null);
    setJoinLoading(true);
    setLoading(true);
    try {
      const match = await joinMatch(roomCode);
      setMatch(match);
      void navigate(`/room/${match.roomCode}`);
    } catch (err) {
      const { message, rejoinMatchId: mid } = parseJoinError(err);
      setJoinError(message);
      if (mid) setRejoinMatchId(mid);
    } finally {
      setJoinLoading(false);
      setLoading(false);
    }
  }

  // ─── Render ──────────────────────────────────────────────────────────────

  const busy = createLoading || joinLoading;

  return (
    <main className="min-h-screen bg-[var(--color-bg-0)] flex flex-col items-center justify-center gap-6 p-4">
      {/* Header */}
      <div className="text-center space-y-1">
        <h1 className="text-3xl font-bold tracking-tight" style={{ fontFamily: 'var(--font-heading)' }}>
          <span className="text-[var(--color-neon-lime)]">♠</span>{' '}
          <span className="text-[var(--color-text-primary)]">Shah Exchange</span>
        </h1>
        {player && (
          <p className="text-[var(--color-text-muted)] text-sm">
            Playing as{' '}
            <span className="font-semibold text-[var(--color-text-primary)]">
              {player.displayName}
            </span>
          </p>
        )}
      </div>

      <div className="w-full max-w-sm space-y-4">
        {/* Active-game rejoin banner */}
        {rejoinMatchId && (
          <div
            role="alert"
            className="flex items-center justify-between gap-3 rounded-lg border border-[var(--color-electric-yellow)]/40 bg-[var(--color-electric-yellow)]/10 px-4 py-3"
          >
            <p className="text-[var(--color-electric-yellow)] text-sm font-medium">
              You still have an active game.
            </p>
            <Button
              variant="default"
              size="sm"
              data-testid="rejoin-game-button"
              onClick={() => void navigate(`/game/${rejoinMatchId}`)}
            >
              Rejoin
            </Button>
          </div>
        )}

        {/* Create Room */}
        <div className="bg-[var(--color-surface)] border border-[var(--color-border)] rounded-lg p-6 space-y-3 shadow-xl">
          <h2 className="text-[var(--color-text-primary)] font-semibold text-lg" style={{ fontFamily: 'var(--font-heading)' }}>
            {COPY.createRoomHeading}
          </h2>
          <p className="text-[var(--color-text-muted)] text-sm">
            {COPY.createRoomBody}
          </p>
          {createError && !rejoinMatchId && (
            <p role="alert" className="text-[var(--color-danger-red)] text-xs">
              {createError}
            </p>
          )}
          <Button
            variant="cta"
            size="lg"
            onClick={() => void handleCreate()}
            disabled={busy}
            data-testid="create-room-button"
            className="w-full"
            aria-label="Create room"
          >
            {createLoading ? (
              <span className="flex items-center gap-2">
                <LoadingSpinner size="sm" />
                Creating…
              </span>
            ) : (
              COPY.createRoom
            )}
          </Button>
        </div>

        {/* Divider */}
        <div className="flex items-center gap-3">
          <hr className="flex-1 border-[var(--color-border)]" />
          <span className="text-[var(--color-text-muted)] text-xs uppercase tracking-widest">
            or
          </span>
          <hr className="flex-1 border-[var(--color-border)]" />
        </div>

        {/* Join Room */}
        <div className="bg-[var(--color-surface)] border border-[var(--color-border)] rounded-lg p-6 space-y-3 shadow-xl">
          <h2 className="text-[var(--color-text-primary)] font-semibold text-lg" style={{ fontFamily: 'var(--font-heading)' }}>
            {COPY.joinRoomHeading}
          </h2>
          <form
            onSubmit={(e) => void handleJoin(e)}
            className="space-y-3"
            noValidate
          >
            <div className="space-y-1.5">
              <label
                htmlFor="roomCode"
                className="block text-[var(--color-text-primary)] text-sm font-medium"
              >
                {COPY.roomCodeLabel}
              </label>
              <input
                id="roomCode"
                type="text"
                data-testid="room-code-input"
                value={roomCode}
                onChange={handleCodeChange}
                maxLength={ROOM_CODE_LENGTH}
                placeholder={COPY.roomCodePlaceholder}
                disabled={busy}
                autoComplete="off"
                aria-invalid={joinError !== null}
                aria-describedby={joinError ? 'join-error' : undefined}
                className="w-full rounded-md border border-[var(--color-electric-yellow)]/40 bg-[var(--color-bg-1)] px-3 py-2 text-[var(--color-electric-yellow)] font-bold uppercase placeholder:text-[var(--color-text-muted)] placeholder:normal-case focus:outline-none focus:ring-2 focus:ring-[var(--color-electric-yellow)] disabled:opacity-50 tracking-widest text-center text-xl transition"
              />
              {joinError && !rejoinMatchId && (
                <p id="join-error" data-testid="join-error" role="alert" className="text-[var(--color-danger-red)] text-xs">
                  {joinError}
                </p>
              )}
            </div>
            <Button
              type="submit"
              variant="default"
              size="lg"
              disabled={busy || roomCode.length !== ROOM_CODE_LENGTH}
              data-testid="join-room-button"
              className="w-full"
              aria-label="Join room"
            >
              {joinLoading ? (
                <span className="flex items-center gap-2">
                  <LoadingSpinner size="sm" />
                  Joining…
                </span>
              ) : (
                COPY.joinRoom
              )}
            </Button>
          </form>
        </div>

        {/* History */}
        <button
          type="button"
          data-testid="view-history-button"
          onClick={() => void navigate('/history')}
          className="w-full text-center text-[var(--color-text-muted)] hover:text-[var(--color-text-primary)] text-sm transition py-1"
        >
          {COPY.viewHistory}
        </button>
      </div>
    </main>
  );
}
