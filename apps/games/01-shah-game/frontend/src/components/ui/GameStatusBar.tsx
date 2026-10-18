/**
 * Top status bar showing current game metadata: game number, round, direction,
 * and whose turn it is. Also provides a Leave Game action.
 */
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { LogOut } from 'lucide-react';
import { useGameStore } from '@/store/gameStore';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { COPY } from '@/lib/copy';
import { leaveMatch } from '@/services/match.service';
import { logger } from '@/lib/logger';

export function GameStatusBar(): React.ReactElement | null {
  const gameState = useGameStore((s) => s.gameState);
  const localPlayerId = useGameStore((s) => s.localPlayerId);
  const navigate = useNavigate();

  const [showLeaveDialog, setShowLeaveDialog] = useState(false);
  const [isLeaving, setIsLeaving] = useState(false);

  if (!gameState) return null;

  const activePlayer = gameState.players[gameState.activePlayerIndex];
  const isMyTurn = activePlayer?.id === localPlayerId;

  const directionLabel =
    gameState.direction === 'clockwise' ? '↻ Clockwise' : '↺ Counter-clockwise';

  async function handleLeaveConfirm(): Promise<void> {
    if (isLeaving) return;
    setIsLeaving(true);
    try {
      await leaveMatch(gameState!.matchId);
      void navigate('/lobby', { replace: true });
    } catch (err) {
      logger.error('Failed to leave match', err);
      setIsLeaving(false);
      setShowLeaveDialog(false);
    }
  }

  return (
    <>
      <div className="flex flex-wrap items-center justify-between gap-2 rounded-lg bg-[var(--color-surface)] border border-[var(--color-border)] px-4 py-2 text-sm shadow-sm">
        <div className="flex items-center gap-3">
          <span className="font-bold text-[var(--color-text-primary)]" style={{ fontFamily: 'var(--font-heading)' }}>
            Game {gameState.gameNumber}
          </span>
          <Badge variant="secondary">Round {gameState.roundNumber}</Badge>
          <span className="text-[var(--color-info-blue)] text-xs">{directionLabel}</span>
        </div>

        <div className="flex items-center gap-2">
          {isMyTurn ? (
            <span className="text-[var(--color-neon-lime)] text-xs font-bold animate-pulse">
              {COPY.yourTurn}
            </span>
          ) : (
            <span className="text-[var(--color-text-muted)] text-xs">
              {activePlayer?.displayName}&apos;s turn
            </span>
          )}

          <Button
            variant="ghost"
            size="sm"
            className="h-7 px-2 text-[var(--color-text-muted)] hover:text-red-400 hover:bg-red-400/10"
            onClick={() => setShowLeaveDialog(true)}
            data-testid="leave-game-button"
            aria-label="Leave game"
          >
            <LogOut className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <Dialog open={showLeaveDialog} onOpenChange={setShowLeaveDialog}>
        <DialogContent showCloseButton={false} className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Leave game?</DialogTitle>
            <DialogDescription>
              You&apos;ll be removed from the match. If too few players remain, the match will end for everyone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="ghost"
              onClick={() => setShowLeaveDialog(false)}
              disabled={isLeaving}
            >
              Stay
            </Button>
            <Button
              variant="destructive"
              onClick={() => void handleLeaveConfirm()}
              disabled={isLeaving}
            >
              {isLeaving ? 'Leaving…' : 'Leave'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}

