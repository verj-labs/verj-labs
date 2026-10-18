/**
 * CardExchangeView
 *
 * Full-screen overlay shown after `game:exchange` fires.
 * Displays each card transfer (giver → receiver + cards given), highlights
 * transfers involving the local player, and counts down 5 seconds until the
 * next game starts.
 *
 * Auto-dismisses when `game:started` fires (handled in useGameSocketSetup via
 * `closeExchangeView`).  The 5-second countdown is decorative / informational.
 *
 * Respects `prefers-reduced-motion` by skipping entrance animations.
 */
import { useEffect, useRef, useState } from 'react';
import { motion, useReducedMotion } from 'framer-motion';
import { type Card } from '@/types/card';
import { useGameStore } from '@/store/gameStore';

// ─── Constants ────────────────────────────────────────────────────────────────

const EXCHANGE_COUNTDOWN_S = 5;

// ─── Helpers ──────────────────────────────────────────────────────────────────

const SUIT_SYMBOLS: Record<string, string> = {
  spades: '♠',
  clubs: '♣',
  diamonds: '♦',
  hearts: '♥',
};

const SUIT_COLORS: Record<string, string> = {
  spades: 'text-foreground',
  clubs: 'text-foreground',
  diamonds: 'text-red-500',
  hearts: 'text-red-500',
};

function CardChip({ card }: { card: Card }) {
  return (
    <span
      className={[
        'inline-flex items-center rounded border border-border bg-card px-1.5 py-0.5 text-sm font-semibold',
        SUIT_COLORS[card.suit] ?? 'text-foreground',
      ].join(' ')}
    >
      {card.rank}
      {SUIT_SYMBOLS[card.suit] ?? card.suit}
    </span>
  );
}

// ─── Component ────────────────────────────────────────────────────────────────

export function CardExchangeView() {
  const isOpen = useGameStore((s) => s.isExchangeViewOpen);
  const summary = useGameStore((s) => s.exchangeSummary);

  if (!isOpen || !summary) return null;

  // Render inner content only when open so useState resets naturally on mount
  return <CardExchangeOverlay />;
}

// ─── Inner component (mounts/unmounts with isOpen) ────────────────────────────

function CardExchangeOverlay() {
  const summary = useGameStore((s) => s.exchangeSummary);
  const localPlayerId = useGameStore((s) => s.localPlayerId);

  const [countdown, setCountdown] = useState(EXCHANGE_COUNTDOWN_S);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const prefersReducedMotion = useReducedMotion();

  // Start countdown on mount; cleanup on unmount
  useEffect(() => {
    intervalRef.current = setInterval(() => {
      setCountdown((c) => Math.max(0, c - 1));
    }, 1_000);

    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, []);

  if (!summary) return null;

  const denominator = EXCHANGE_COUNTDOWN_S;
  const progressPct = (countdown / denominator) * 100;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Card exchange"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm"
    >
      <motion.div
        initial={prefersReducedMotion ? false : { y: 40, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.3 }}
        className="w-full max-w-md rounded-2xl border border-border bg-card p-6 shadow-2xl"
      >
        <h2 className="mb-1 text-center text-2xl font-bold text-foreground">
          Card Exchange
        </h2>
        <p className="mb-5 text-center text-sm text-muted-foreground">
          Cards are distributed before the next game
        </p>

        {/* Exchange rows */}
        <ul className="space-y-3">
          {summary.exchanges.map((action, i) => {
            const involvesLocal =
              action.giverId === localPlayerId || action.receiverId === localPlayerId;

            return (
              <motion.li
                key={`${action.giverId}-${action.receiverId}-${i}`}
                initial={prefersReducedMotion ? false : { x: -16, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: i * 0.07 }}
                className={[
                  'rounded-xl border px-4 py-3',
                  involvesLocal
                    ? 'border-primary/50 bg-primary/5'
                    : 'border-border bg-muted/30',
                ].join(' ')}
              >
                {/* Header: giver → receiver */}
                <div className="mb-2 flex items-center gap-2 text-sm font-medium">
                  <span
                    className={
                      action.giverId === localPlayerId ? 'text-primary' : 'text-foreground'
                    }
                  >
                    {action.giverId === localPlayerId ? 'You' : action.giverName}
                  </span>
                  <span className="text-muted-foreground">→</span>
                  <span
                    className={
                      action.receiverId === localPlayerId ? 'text-primary' : 'text-foreground'
                    }
                  >
                    {action.receiverId === localPlayerId ? 'You' : action.receiverName}
                  </span>
                  {involvesLocal && (
                    <span className="ml-auto rounded-full bg-primary/10 px-2 py-0.5 text-xs text-primary">
                      {action.receiverId === localPlayerId ? '← you receive' : 'you give →'}
                    </span>
                  )}
                </div>

                {/* Cards */}
                <div className="flex flex-wrap gap-1.5">
                  {action.cardsGiven.map((c) => (
                    <CardChip key={`${c.rank}-${c.suit}`} card={c} />
                  ))}
                </div>
              </motion.li>
            );
          })}
        </ul>

        {/* Countdown progress bar */}
        <div className="mt-6">
          <div className="flex justify-between text-xs text-muted-foreground">
            <span>Next game starting…</span>
            <span>{countdown}s</span>
          </div>
          <div className="mt-1.5 h-1.5 w-full overflow-hidden rounded-full bg-muted">
            <motion.div
              className="h-full rounded-full bg-primary"
              animate={{ width: `${progressPct}%` }}
              transition={{ duration: 0.9, ease: 'linear' }}
            />
          </div>
        </div>
      </motion.div>
    </div>
  );
}
