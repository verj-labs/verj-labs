/**
 * Play / Pass action bar.  Only active on the local player's turn.
 */
import React from 'react';
import { useGameStore, selectIsMyTurn } from '@/store/gameStore';
import { sendPass, sendPlay } from '@/services/gameActions';
import { Button } from '@/components/ui/button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { COPY } from '@/lib/copy';

export function ActionBar(): React.ReactElement | null {
  const gameState = useGameStore((s) => s.gameState);
  const selectedCards = useGameStore((s) => s.selectedCards);
  const isActionPending = useGameStore((s) => s.isActionPending);
  const lastActionError = useGameStore((s) => s.lastActionError);
  const setActionPending = useGameStore((s) => s.setActionPending);
  const setActionError = useGameStore((s) => s.setActionError);
  const clearSelection = useGameStore((s) => s.clearSelection);
  const isMyTurn = useGameStore(selectIsMyTurn);

  if (!gameState || gameState.status === 'finished') return null;

  async function handlePlay(): Promise<void> {
    if (selectedCards.length === 0 || isActionPending) return;
    setActionPending(true);
    setActionError(null);
    try {
      await sendPlay(selectedCards);
      clearSelection();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Play failed.');
    } finally {
      setActionPending(false);
    }
  }

  async function handlePass(): Promise<void> {
    if (isActionPending) return;
    setActionPending(true);
    setActionError(null);
    try {
      await sendPass();
      clearSelection();
    } catch (err) {
      setActionError(err instanceof Error ? err.message : 'Pass failed.');
    } finally {
      setActionPending(false);
    }
  }

  return (
    <div className="flex flex-col items-center gap-2">
      {lastActionError && (
        <p className="text-sm text-[var(--color-danger-red)]" role="alert">
          {lastActionError}
        </p>
      )}

      <div className="flex gap-3">
        <Button
          onClick={() => void handlePlay()}
          disabled={!isMyTurn || selectedCards.length === 0 || isActionPending}
          data-testid="play-button"
          variant="default"
          size="lg"
          className="min-w-28"
        >
          {isActionPending ? <LoadingSpinner size="sm" color="text-[var(--color-bg-0)]" /> : null}
          {selectedCards.length > 0 ? COPY.playCount(selectedCards.length) : COPY.play}
        </Button>

        <Button
          variant="ghost"
          size="lg"
          onClick={() => void handlePass()}
          disabled={!isMyTurn || isActionPending}
          data-testid="pass-button"
          className="min-w-28"
        >
          {isActionPending ? <LoadingSpinner size="sm" /> : null}
          {COPY.pass}
        </Button>
      </div>

      {!isMyTurn && gameState.status === 'in_progress' && (
        <p className="text-xs text-muted-foreground">
          Waiting for {gameState.players[gameState.activePlayerIndex]?.displayName}…
        </p>
      )}
    </div>
  );
}
