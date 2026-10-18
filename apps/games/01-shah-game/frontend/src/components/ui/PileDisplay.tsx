/**
 * Displays the current discard pile — shows the top play and how many prior
 * plays are stacked underneath.
 *
 * Framer Motion:
 * - New top-play cards slide in from below when played.
 * - When a pile reset fires (pileResetPending=true), cards scatter outward
 *   before the pile clears.  The pile container also shows a brief red glow.
 */
import React from 'react';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { useGameStore } from '@/store/gameStore';
import { PlayingCard } from './PlayingCard';
import type { Card } from '@/types/card';

export function PileDisplay(): React.ReactElement | null {
  const gameState = useGameStore((s) => s.gameState);
  const pileResetPending = useGameStore((s) => s.pileResetPending);
  const prefersReducedMotion = useReducedMotion();

  if (!gameState) return null;

  const { pile } = gameState.currentRound;
  const topPlay = pile.topPlay;
  const historyDepth = pile.history.length;

  return (
    <div className="flex flex-col items-center gap-2">
      <span className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
        Pile {historyDepth > 0 ? `(${historyDepth} plays)` : '(empty)'}
      </span>

      {/* Glow container — briefly red when pile resets */}
      <motion.div
        animate={pileResetPending && !prefersReducedMotion
          ? { boxShadow: '0 0 24px 6px rgba(255,59,59,0.45)', scale: 1.04 }
          : { boxShadow: '0 0 0px 0px rgba(255,59,59,0)', scale: 1 }
        }
        transition={{ duration: 0.35, ease: 'easeOut' }}
        className="rounded-lg"
      >
        <AnimatePresence mode="wait">
          {topPlay ? (
            <motion.div
              key={`play-${historyDepth}`}
              data-testid="pile-top"
              className="flex gap-1"
              initial={prefersReducedMotion ? false : { y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              exit={
                pileResetPending && !prefersReducedMotion
                  ? { y: -30, opacity: 0, scale: 0.6, transition: { duration: 0.3 } }
                  : { opacity: 0 }
              }
              transition={{ duration: 0.2, ease: 'easeOut' }}
            >
              {topPlay.cards.map((card: Card, i) => (
                <motion.div
                  key={`${card.rank}-${card.suit}-${i}`}
                  initial={prefersReducedMotion ? false : { y: 16, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  transition={{ delay: i * 0.06, duration: 0.18 }}
                >
                  <PlayingCard rank={card.rank} suit={card.suit} />
                </motion.div>
              ))}
            </motion.div>
          ) : (
            <motion.div
              key="empty"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="flex h-20 w-16 items-center justify-center rounded-lg border-2 border-dashed border-muted-foreground/30 text-xs text-muted-foreground"
            >
              Empty
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </div>
  );
}
