/**
 * Small status indicator beneath the pile showing players who have passed
 * this round.
 */
import React from 'react';
import { useGameStore } from '@/store/gameStore';

export function PassIndicator(): React.ReactElement | null {
  const gameState = useGameStore((s) => s.gameState);

  if (!gameState) return null;

  const passedPlayers = gameState.players.filter((p) => p.passed && !p.isFinished);

  if (passedPlayers.length === 0) return null;

  return (
    <div className="flex flex-wrap justify-center gap-1 text-xs text-muted-foreground">
      <span>Passed:</span>
      {passedPlayers.map((p) => (
        <span key={p.id} className="font-medium">
          {p.displayName}
        </span>
      ))}
    </div>
  );
}
