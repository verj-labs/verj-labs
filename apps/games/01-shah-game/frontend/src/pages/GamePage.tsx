import { useParams } from 'react-router-dom';
import { ActionBar } from '@/components/ui/ActionBar';
import { ConnectionBanner } from '@/components/ui/ConnectionBanner';
import { GameStatusBar } from '@/components/ui/GameStatusBar';
import { LocalPlayerHand } from '@/components/ui/LocalPlayerHand';
import { OpponentSection } from '@/components/ui/OpponentSection';
import { PassIndicator } from '@/components/ui/PassIndicator';
import { PileDisplay } from '@/components/ui/PileDisplay';
import { Scoreboard } from '@/components/ui/Scoreboard';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import { CardExchangeView } from '@/features/game/CardExchangeView';
import { GameFinishedOverlay } from '@/features/game/GameFinishedOverlay';
import { SkipOverlay } from '@/features/game/SkipOverlay';
import { ResetOverlay } from '@/features/game/ResetOverlay';
import { useGameSocketSetup } from '@/hooks/useGameSocketSetup';
import { useGameStore } from '@/store/gameStore';

export default function GamePage() {
  const { matchId } = useParams<{ matchId: string }>();
  const gameState = useGameStore((s) => s.gameState);
  const isGameFinishedOverlayOpen = useGameStore((s) => s.isGameFinishedOverlayOpen);

  // Attach all socket event handlers for this game
  useGameSocketSetup(matchId ?? '');

  if (!gameState) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-[var(--color-bg-0)]">
        <LoadingSpinner size="lg" />
        <p className="text-[var(--color-text-muted)] text-sm">Loading the chaos…</p>
      </div>
    );
  }

  return (
    <div data-testid="game-board" className="relative flex min-h-screen flex-col bg-[var(--color-bg-0)]">
      <ConnectionBanner />

      {/* Top status bar */}
      <div className="sticky top-0 z-10 bg-[var(--color-bg-0)]/90 px-4 py-2 backdrop-blur border-b border-[var(--color-border)] space-y-2">
        <GameStatusBar />
        <Scoreboard />
      </div>

      {/* Main board */}
      <div className="flex flex-1 flex-col gap-6 p-4 pb-28 sm:pb-4">
        {/* Opponents across the top */}
        <OpponentSection />

        {/* Central table area: pile + pass indicators */}
        <div className="flex flex-1 flex-col items-center justify-center gap-3">
          <PileDisplay />
          <PassIndicator />
        </div>

        {/* Local player's hand */}
        <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] p-3 shadow-sm">
          <p className="mb-2 text-center text-xs font-medium uppercase tracking-wide text-[var(--color-text-muted)]">
            Your Hand
          </p>
          <LocalPlayerHand />
        </div>

        {/* Action buttons — fixed to bottom on mobile, inline on larger screens */}
        <div className="fixed bottom-0 left-0 right-0 z-20 border-t border-[var(--color-border)] bg-[var(--color-bg-0)]/95 px-4 py-3 backdrop-blur sm:relative sm:bottom-auto sm:left-auto sm:right-auto sm:z-auto sm:border-none sm:bg-transparent sm:p-0 sm:[backdrop-filter:none]">
          <ActionBar />
        </div>
      </div>

      {/* ── Overlays (z-50, rendered above everything) ── */}
      <GameFinishedOverlay />
      {/* CardExchangeView is only shown once GameFinishedOverlay has dismissed,
          so the 'End Match' button inside GameFinishedOverlay is never blocked. */}
      {!isGameFinishedOverlayOpen && <CardExchangeView />}
      <SkipOverlay />
      <ResetOverlay />
    </div>
  );
}

