/**
 * Represents the back of an opponent's hand — just a row of face-down card
 * shapes with a count label beneath.
 *
 * Framer Motion:
 * - A red flash overlay shows when this player is skipped.
 * - The finish rank badge slides in from above with a spring when the player
 *   finishes.
 */
import React from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { useGameStore } from '@/store/gameStore';
import { type PlayerView } from '@/types/game-state';

interface OpponentHandProps {
  player: PlayerView;
  isActive: boolean;
}

export function OpponentHand({ player, isActive }: OpponentHandProps): React.ReactElement {
  const skippedPlayerId = useGameStore((s) => s.skippedPlayerId);
  const prefersReducedMotion = useReducedMotion();

  const isSkipped = skippedPlayerId === player.id;
  const cards = Array.from({ length: player.handCount }, (_, i) => i);

  return (
    <motion.div
      className={`relative flex flex-col items-center gap-1 rounded-lg p-2 transition-colors ${
        isActive ? 'bg-[var(--color-neon-lime)]/10 ring-2 ring-[var(--color-neon-lime)]' : ''
      }`}
      aria-label={`${player.displayName}'s hand (${player.handCount} cards)`}
    >
      {/* Skip flash overlay */}
      <AnimatePresence>
        {isSkipped && !prefersReducedMotion && (
          <motion.div
            key="skip-flash"
            className="pointer-events-none absolute inset-0 rounded-lg bg-[var(--color-hot-pink)]/30"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.15 }}
            aria-hidden="true"
          />
        )}
      </AnimatePresence>

      <div className="flex gap-0.5">
        {cards.slice(0, Math.min(cards.length, 10)).map((i) => (
          <div
            key={i}
            className="h-10 w-7 rounded-sm border border-[var(--color-border)] bg-[var(--color-card-back)] shadow-sm"
            aria-hidden="true"
          />
        ))}
        {player.handCount > 10 && (
          <span className="ml-1 self-center text-xs text-muted-foreground">
            +{player.handCount - 10}
          </span>
        )}
      </div>

      <div className="flex items-center gap-1 text-xs font-medium">
        <span>{player.displayName}</span>
        <AnimatePresence>
          {player.isFinished && player.finishRank !== null && (
            <motion.span
              key="finish-badge"
              className="text-yellow-500"
              initial={prefersReducedMotion ? false : { y: -10, opacity: 0, scale: 0.6 }}
              animate={{ y: 0, opacity: 1, scale: 1 }}
              transition={{ type: 'spring', stiffness: 400, damping: 20 }}
            >
              #{player.finishRank}
            </motion.span>
          )}
        </AnimatePresence>
        {player.passed && !player.isFinished && (
          <span className="text-muted-foreground">(passed)</span>
        )}
        <span className="text-muted-foreground">({player.handCount})</span>
      </div>
    </motion.div>
  );
}
