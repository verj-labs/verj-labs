/**
 * SkipOverlay
 *
 * Full-viewport flash shown when a `game:player_skipped` event fires.
 * Reads `skippedPlayerId` from gameStore, resolves the display name from the
 * current game state, and auto-dismisses after DISMISS_MS.
 *
 * pointer-events-none — never blocks user interaction.
 * Respects prefers-reduced-motion via Framer Motion.
 */
import { useEffect, useRef, useState } from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { useGameStore } from '@/store/gameStore';
import { randomSkipPhrase } from '@/lib/copy';
import type { PlayerView } from '@/types/game-state';

// ─── Constants ────────────────────────────────────────────────────────────────

const DISMISS_MS = 1500;
const ROTATIONS = [-12, -8, -5, 5, 8, 12] as const;

function pickRotation(): number {
  return ROTATIONS[Math.floor(Math.random() * ROTATIONS.length)];
}

// ─── Component ────────────────────────────────────────────────────────────────

export function SkipOverlay() {
  const skippedPlayerId = useGameStore((s) => s.skippedPlayerId);
  const gameState = useGameStore((s) => s.gameState);
  const prefersReducedMotion = useReducedMotion();

  const [visible, setVisible] = useState(false);
  const [capturedName, setCapturedName] = useState('');
  const [phrase, setPhrase] = useState('');
  const [rotate, setRotate] = useState(0);

  // Keep a ref to the current player list so the timer effect can look up the
  // display name WITHOUT listing gameState.players in its own deps array.
  // If gameState.players were a dep, any game:state_updated received while the
  // overlay is visible would trigger the effect cleanup — cancelling the dismiss
  // timer and leaving the overlay permanently on screen.
  const playersRef = useRef<PlayerView[]>([]);
  useEffect(() => {
    playersRef.current = gameState?.players ?? [];
  }, [gameState?.players]);

  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (!skippedPlayerId) return; // store cleared after 600ms — timer already running, ignore

    // Cancel any in-flight timer (same player skipped again before overlay dismissed)
    if (timerRef.current) clearTimeout(timerRef.current);

    const name =
      playersRef.current.find((p) => p.id === skippedPlayerId)?.displayName ??
      'Someone';

    setCapturedName(name);
    setPhrase(randomSkipPhrase());
    setRotate(pickRotation());
    setVisible(true);

    // Timer lives in a ref — NOT returned as cleanup — so the store's null
    // reset cannot cancel it mid-flight.
    timerRef.current = setTimeout(() => {
      setVisible(false);
      timerRef.current = null;
    }, DISMISS_MS);
  }, [skippedPlayerId]);

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 pointer-events-none"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0, transition: { duration: 0.35 } }}
          aria-label={`${capturedName} was skipped`}
          role="status"
          aria-live="assertive"
        >
          <motion.div
            style={{ rotate, color: 'var(--color-hot-pink)' }}
            initial={prefersReducedMotion ? false : { scale: 0.5, opacity: 0 }}
            animate={
              prefersReducedMotion
                ? { opacity: 1 }
                : { scale: [0.5, 1.15, 1.0], opacity: 1 }
            }
            transition={{ duration: 0.25, type: 'spring', stiffness: 600 }}
            className="flex flex-col items-center gap-3 select-none text-center"
          >
            <span
              className="font-[var(--font-heading)] font-bold text-7xl leading-none neon-glow-pink"
              data-testid="skip-overlay-title"
            >
              SKIP!
            </span>
            <p className="font-[var(--font-heading)] text-2xl text-white/90">
              {capturedName}
            </p>
            <p className="text-base text-[var(--color-hot-pink)]/80">
              {phrase}
            </p>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
