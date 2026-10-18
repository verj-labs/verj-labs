/**
 * GameFinishedOverlay
 *
 * Full-screen modal shown when `game:finished` fires.
 *   1. If the local player won (rank 1), show a 2-second celebration screen.
 *   2. Show the full rankings list with medal emojis.
 *   3. After a 3-second countdown (from the moment rankings appear), the
 *      overlay dismisses itself so the CardExchangeView can take over.
 */
import { useEffect, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { toast } from 'sonner';
import api from '@/services/api';
import { logger } from '@/lib/logger';
import { useGameStore } from '@/store/gameStore';
import { useMatchStore } from '@/store/matchStore';
import { useSessionStore } from '@/store/sessionStore';

// ─── Constants ────────────────────────────────────────────────────────────────

const CELEBRATION_DURATION_MS = 2_000;
const RANKINGS_COUNTDOWN_S = 3;

// ─── Helpers ──────────────────────────────────────────────────────────────────

function medal(rank: number): string {
  if (rank === 1) return '🥇';
  if (rank === 2) return '🥈';
  if (rank === 3) return '🥉';
  return `${rank}.`;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function GameFinishedOverlay() {
  const isOpen = useGameStore((s) => s.isGameFinishedOverlayOpen);
  const rankings = useGameStore((s) => s.gameFinishedRankings);
  const localPlayerId = useGameStore((s) => s.localPlayerId);
  const closeFinishedOverlay = useGameStore((s) => s.closeFinishedOverlay);
  const matchId = useMatchStore((s) => s.matchId);
  const hostPlayerId = useMatchStore((s) => s.hostPlayerId);
  const playerId = useSessionStore((s) => s.player?.id);

  const localRank = rankings?.find((r) => r.playerId === localPlayerId)?.rank ?? null;
  const isWinner = localRank === 1;

  // Show the "You won!" celebration, then transition to rankings
  const [showCelebration, setShowCelebration] = useState(false);
  const [countdown, setCountdown] = useState(RANKINGS_COUNTDOWN_S);
  const closedRef = useRef(false);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (!isOpen) {
      // Reset local state for next time
      setShowCelebration(false);
      setCountdown(RANKINGS_COUNTDOWN_S);
      closedRef.current = false;
      return;
    }

    closedRef.current = false;

    if (isWinner) {
      setShowCelebration(true);
      const celebTimer = setTimeout(() => {
        setShowCelebration(false);
        startCountdown();
      }, CELEBRATION_DURATION_MS);
      return () => {
        clearTimeout(celebTimer);
        if (intervalRef.current) clearInterval(intervalRef.current);
      };
    } else {
      startCountdown();
      return () => {
        if (intervalRef.current) clearInterval(intervalRef.current);
      };
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isOpen]);

  // Auto-close once the countdown reaches 0 — kept separate so we never call
  // closeFinishedOverlay() from inside a React state-updater function.
  useEffect(() => {
    if (isOpen && countdown === 0 && !showCelebration && !closedRef.current) {
      closedRef.current = true;
      closeFinishedOverlay();
    }
  }, [countdown, isOpen, showCelebration, closeFinishedOverlay]);

  function startCountdown() {
    setCountdown(RANKINGS_COUNTDOWN_S);
    if (intervalRef.current) clearInterval(intervalRef.current);
    intervalRef.current = setInterval(() => {
      setCountdown((c) => {
        if (c <= 1) {
          if (intervalRef.current) clearInterval(intervalRef.current);
          intervalRef.current = null;
          return 0;
        }
        return c - 1;
      });
    }, 1_000);
  }

  const isHost = !!playerId && playerId === hostPlayerId;
  const [isEndingMatch, setIsEndingMatch] = useState(false);

  async function handleEndMatch(): Promise<void> {
    if (!matchId || isEndingMatch) return;
    setIsEndingMatch(true);
    try {
      await api.post(`/match/${matchId}/end`);
      // Navigation is handled by the match:finished socket event in useGameSocketSetup
    } catch (err) {
      logger.error('[GameFinishedOverlay] endMatch failed:', err);
      toast.error('Could not end the match. Please try again.');
      setIsEndingMatch(false);
    }
  }

  if (!isOpen || !rankings) return null;

  // ── Render ──────────────────────────────────────────────────────────────────

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Game results"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm"
    >
      <AnimatePresence mode="wait">
        {showCelebration ? (
          /* ── Celebration screen ────────────────────────────────────────── */
          <motion.div
            key="celebration"
            initial={{ scale: 0.5, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 1.2, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 260, damping: 20 }}
            className="flex flex-col items-center gap-4 text-center"
          >
            <span className="text-8xl">🏆</span>
            <h2 className="text-5xl font-bold text-[var(--color-electric-yellow)] drop-shadow-lg">
              You won!
            </h2>
          </motion.div>
        ) : (
          /* ── Rankings screen ────────────────────────────────────────────── */
          <motion.div
            key="rankings"
            initial={{ y: 40, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: -40, opacity: 0 }}
            transition={{ duration: 0.3 }}
            className="w-full max-w-sm rounded-2xl border border-border bg-card p-6 shadow-2xl"
          >
            <h2 className="mb-4 text-center text-2xl font-bold text-foreground">
              Game Results
            </h2>

            <ul className="space-y-2">
              {rankings
                .slice()
                .sort((a, b) => a.rank - b.rank)
                .map((entry, i) => (
                  <motion.li
                    key={entry.playerId}
                    initial={{ x: -20, opacity: 0 }}
                    animate={{ x: 0, opacity: 1 }}
                    transition={{ delay: i * 0.08 }}
                    className={[
                      'flex items-center gap-3 rounded-lg px-3 py-2',
                      entry.playerId === localPlayerId
                        ? 'bg-primary/10 ring-1 ring-primary'
                        : 'bg-muted/40',
                    ].join(' ')}
                  >
                    <span className="w-8 text-center text-xl">
                      {medal(entry.rank)}
                    </span>
                    <span
                      className={[
                        'flex-1 font-medium',
                        entry.playerId === localPlayerId
                          ? 'text-primary'
                          : 'text-foreground',
                      ].join(' ')}
                    >
                      {entry.displayName}
                      {entry.playerId === localPlayerId && (
                        <span className="ml-1 text-xs text-muted-foreground">(you)</span>
                      )}
                    </span>
                  </motion.li>
                ))}
            </ul>

            {/* Countdown footer */}
            <p className="mt-5 text-center text-sm text-muted-foreground">
              Card exchange in{' '}
              <span className="font-semibold text-foreground">{countdown}</span>…
            </p>

            {/* Host-only: end match early */}
            {isHost && (
              <button
                onClick={() => void handleEndMatch()}
                disabled={isEndingMatch}
                className="mt-4 w-full rounded-lg border border-destructive/50 bg-destructive/10 px-4 py-2 text-sm font-medium text-destructive transition-colors hover:bg-destructive/20 disabled:cursor-not-allowed disabled:opacity-50"
                data-testid="end-match-button"
              >
                {isEndingMatch ? 'Ending match…' : 'End Match'}
              </button>
            )}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
