/**
 * Section at the top of the board that lays out all opponent hands in a row.
 */
import React from 'react';
import { useGameStore } from '@/store/gameStore';
import { OpponentHand } from './OpponentHand';

export function OpponentSection(): React.ReactElement | null {
  const gameState = useGameStore((s) => s.gameState);
  const localPlayerId = useGameStore((s) => s.localPlayerId);

  if (!gameState) return null;

  const opponents = gameState.players.filter((p) => p.id !== localPlayerId);

  if (opponents.length === 0) return null;

  return (
    <div className="flex flex-wrap justify-center gap-4">
      {opponents.map((player) => (
        <OpponentHand
          key={player.id}
          player={player}
          isActive={gameState.players[gameState.activePlayerIndex]?.id === player.id}
        />
      ))}
    </div>
  );
}
