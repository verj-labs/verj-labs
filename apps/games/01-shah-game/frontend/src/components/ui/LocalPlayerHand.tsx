/**
 * Shows the local player's hand.  Cards can be selected / deselected to build
 * a play set.
 *
 * Framer Motion: cards animate in with a stagger on each new game (keyed by
 * gameNumber).  Respects prefers-reduced-motion.
 */
import React from 'react';
import { motion, useReducedMotion } from 'framer-motion';
import { useGameStore } from '@/store/gameStore';
import { PlayingCard } from './PlayingCard';
import { sortCards } from '@/types/card';
import type { Card } from '@/types/card';
import { cardKey, computePlayableCards } from '@/lib/playable';

export function LocalPlayerHand(): React.ReactElement | null {
  const gameState = useGameStore((s) => s.gameState);
  const localPlayerId = useGameStore((s) => s.localPlayerId);
  const isActionPending = useGameStore((s) => s.isActionPending);
  const toggleCardSelection = useGameStore((s) => s.toggleCardSelection);
  const selectedCards = useGameStore((s) => s.selectedCards);
  const prefersReducedMotion = useReducedMotion();

  if (!gameState) return null;

  const isMyTurn =
    gameState.players[gameState.activePlayerIndex]?.id === localPlayerId;

  const hand = sortCards(gameState.localHand);

  // Cards that can form a valid play given the current pile (UX gate — backend
  // is still the authoritative validator).  On an empty pile every card opens
  // a new round so all are enabled.
  const topPlay = gameState.currentRound.pile.topPlay;
  const playableSet = computePlayableCards(hand, topPlay);

  // When ≥1 card is already selected, only the same rank may be added to the
  // set (the backend rejects mixed-rank plays with "All played cards must have
  // the same rank.").
  const selectionRank = selectedCards[0]?.rank ?? null;

  if (hand.length === 0) {
    return (
      <div className="flex justify-center py-4 text-sm text-muted-foreground">
        Your hand is empty.
      </div>
    );
  }

  return (
    // Key on gameNumber so the stagger re-plays at the start of each game
    <div
      key={gameState.gameNumber}
      data-testid="local-hand"
      className="flex flex-wrap justify-center gap-1 py-2"
    >
      {hand.map((card: Card, i) => {
        const isSelected = selectedCards.some(
          (c) => c.rank === card.rank && c.suit === card.suit,
        );

        // A card is interactive only when:
        //  1. It is the local player's turn and no action is in flight
        //  2. The pile allows this card's rank+count combination (or pile empty)
        //  3. No same-rank restriction from an already-selected card
        const pileBlocks =
          !isSelected && topPlay !== null && !playableSet.has(cardKey(card));
        const rankBlocks =
          !isSelected && selectionRank !== null && card.rank !== selectionRank;
        const isDisabled =
          !isMyTurn || isActionPending || pileBlocks || rankBlocks;

        return (
          <motion.div
            key={`${card.rank}-${card.suit}-${i}`}
            initial={prefersReducedMotion ? false : { y: 40, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: i * 0.05, duration: 0.25, ease: 'easeOut' }}
          >
            <PlayingCard
              rank={card.rank}
              suit={card.suit}
              selected={isSelected}
              disabled={isDisabled}
              onClick={
                !isDisabled
                  ? () => toggleCardSelection(card)
                  : undefined
              }
            />
          </motion.div>
        );
      })}
    </div>
  );
}
