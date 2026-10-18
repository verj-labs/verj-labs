/**
 * Scoreboard
 *
 * Compact in-game player standings strip.  Shows every player in seat order
 * with their remaining card count and finish rank (if they've already placed).
 *
 * Layout: horizontal scrollable row of player "chips" so it never pushes the
 * table area off-screen on small devices.
 */
import React from 'react';
import { cn } from '@/lib/utils';
import { useGameStore } from '@/store/gameStore';
import type { PlayerView } from '@/types/game-state';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function rankMedal(rank: number): string {
  if (rank === 1) return '🥇';
  if (rank === 2) return '🥈';
  if (rank === 3) return '🥉';
  return `#${rank}`;
}

// ─── Sub-component: one player chip ──────────────────────────────────────────

interface PlayerChipProps {
  player: PlayerView;
  isActive: boolean;
  isLocal: boolean;
}

function PlayerChip({ player, isActive, isLocal }: PlayerChipProps) {
  const finished = player.isFinished && player.finishRank !== null;

  return (
    <div
      data-testid={`scoreboard-player-${player.id}`}
      className={cn(
        'flex shrink-0 items-center gap-2 rounded-lg px-3 py-1.5 text-sm border transition-all',
        // Active player — neon-lime glow
        isActive &&
          'border-[var(--color-neon-lime)] bg-[var(--color-neon-lime)]/10 shadow-[0_0_8px_var(--color-neon-lime)] shadow-[var(--color-neon-lime)]/30',
        // Local player (not active) — info-blue tint
        isLocal &&
          !isActive &&
          'border-[var(--color-info-blue)]/60 bg-[var(--color-info-blue)]/10',
        // Finished (not local, not active)
        finished &&
          !isActive &&
          !isLocal &&
          'border-[var(--color-border)] bg-[var(--color-surface)] opacity-60',
        // Default
        !isActive &&
          !isLocal &&
          !finished &&
          'border-[var(--color-border)] bg-[var(--color-surface)]',
      )}
    >
      {/* Active indicator pulse */}
      {isActive && (
        <span
          aria-hidden="true"
          className="h-1.5 w-1.5 shrink-0 rounded-full bg-[var(--color-neon-lime)] animate-pulse"
        />
      )}

      {/* Name */}
      <span
        className={cn(
          'font-medium truncate max-w-[80px]',
          isLocal
            ? 'text-[var(--color-info-blue)]'
            : finished
              ? 'text-[var(--color-text-muted)]'
              : 'text-[var(--color-text-primary)]',
          isActive && 'text-[var(--color-neon-lime)]',
        )}
      >
        {isLocal ? 'You' : player.displayName}
      </span>

      {/* Card count  OR  finish rank */}
      {finished ? (
        <span
          aria-label={`finished rank ${player.finishRank}`}
          className="text-base leading-none"
        >
          {rankMedal(player.finishRank!)}
        </span>
      ) : (
        <span
          aria-label={`${player.handCount} cards`}
          className={cn(
            'flex h-5 min-w-[1.2rem] items-center justify-center rounded-full px-1 text-xs font-bold tabular-nums',
            isActive
              ? 'bg-[var(--color-neon-lime)] text-[var(--color-bg-0)]'
              : isLocal
                ? 'bg-[var(--color-info-blue)]/20 text-[var(--color-info-blue)]'
                : 'bg-[var(--color-bg-1)] text-[var(--color-text-muted)]',
          )}
        >
          {player.handCount}
        </span>
      )}
    </div>
  );
}

// ─── Main component ───────────────────────────────────────────────────────────

export function Scoreboard(): React.ReactElement | null {
  const gameState = useGameStore((s) => s.gameState);
  const localPlayerId = useGameStore((s) => s.localPlayerId);

  if (!gameState) return null;

  // Sort: unfinished players by seat index first, finished players at the end
  // sorted by their finish rank so you can see the leaderboard build up.
  const sortedPlayers: PlayerView[] = [
    ...gameState.players
      .filter((p) => !p.isFinished)
      .sort((a, b) => a.seatIndex - b.seatIndex),
    ...gameState.players
      .filter((p) => p.isFinished)
      .sort((a, b) => (a.finishRank ?? 99) - (b.finishRank ?? 99)),
  ];

  const activePlayerId =
    gameState.players[gameState.activePlayerIndex]?.id ?? null;

  return (
    <div
      aria-label="Scoreboard"
      className="flex items-center gap-2 overflow-x-auto py-1 scrollbar-none"
    >
      <span className="shrink-0 text-[10px] font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
        Players
      </span>
      {sortedPlayers.map((player) => (
        <PlayerChip
          key={player.id}
          player={player}
          isActive={player.id === activePlayerId}
          isLocal={player.id === localPlayerId}
        />
      ))}
    </div>
  );
}
