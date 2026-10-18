import { act, render, screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { GameFinishedOverlay } from '@/features/game/GameFinishedOverlay';
import { useGameStore } from '@/store/gameStore';

// ─── Mock framer-motion ───────────────────────────────────────────────────────

vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...rest }: React.ComponentPropsWithoutRef<'div'>) => (
      <div {...rest}>{children}</div>
    ),
    li: ({ children, ...rest }: React.ComponentPropsWithoutRef<'li'>) => (
      <li {...rest}>{children}</li>
    ),
  },
  AnimatePresence: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

// ─── Helpers ──────────────────────────────────────────────────────────────────

const RANKINGS = [
  { playerId: 'p1', displayName: 'Alice', rank: 1 },
  { playerId: 'p2', displayName: 'Bob', rank: 2 },
  { playerId: 'p3', displayName: 'Carol', rank: 3 },
  { playerId: 'p4', displayName: 'Dave', rank: 4 },
];

function resetStore() {
  useGameStore.getState().clearGame();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('GameFinishedOverlay', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    resetStore();
  });

  afterEach(() => {
    vi.useRealTimers();
    resetStore();
  });

  it('renders nothing when the overlay is closed', () => {
    const { container } = render(<GameFinishedOverlay />);
    expect(container).toBeEmptyDOMElement();
  });

  it('renders the rankings when opened', () => {
    useGameStore.getState().showFinishedOverlay(RANKINGS);
    render(<GameFinishedOverlay />);

    expect(screen.getByRole('dialog')).toBeInTheDocument();
    expect(screen.getByText('Game Results')).toBeInTheDocument();
    expect(screen.getByText('Alice')).toBeInTheDocument();
    expect(screen.getByText('Bob')).toBeInTheDocument();
    expect(screen.getByText('Carol')).toBeInTheDocument();
    expect(screen.getByText('Dave')).toBeInTheDocument();
  });

  it('shows medal emojis for top-3 positions', () => {
    useGameStore.getState().showFinishedOverlay(RANKINGS);
    render(<GameFinishedOverlay />);

    expect(screen.getByText('🥇')).toBeInTheDocument();
    expect(screen.getByText('🥈')).toBeInTheDocument();
    expect(screen.getByText('🥉')).toBeInTheDocument();
  });

  it('highlights the local player row and adds "(you)" label', () => {
    useGameStore.getState().setLocalPlayerId('p2');
    useGameStore.getState().showFinishedOverlay(RANKINGS);
    render(<GameFinishedOverlay />);

    expect(screen.getByText('(you)')).toBeInTheDocument();
  });

  it('shows the "You won!" celebration screen for 1st-place local player', () => {
    useGameStore.getState().setLocalPlayerId('p1');
    useGameStore.getState().showFinishedOverlay(RANKINGS);
    render(<GameFinishedOverlay />);

    expect(screen.getByText('You won!')).toBeInTheDocument();
    // Rankings not yet visible
    expect(screen.queryByText('Game Results')).not.toBeInTheDocument();
  });

  it('transitions from celebration to rankings after 2 seconds', () => {
    useGameStore.getState().setLocalPlayerId('p1');
    useGameStore.getState().showFinishedOverlay(RANKINGS);
    render(<GameFinishedOverlay />);

    expect(screen.getByText('You won!')).toBeInTheDocument();

    act(() => {
      vi.advanceTimersByTime(2_000);
    });

    expect(screen.queryByText('You won!')).not.toBeInTheDocument();
    expect(screen.getByText('Game Results')).toBeInTheDocument();
  });

  it('shows initial countdown value of 3', () => {
    useGameStore.getState().showFinishedOverlay(RANKINGS);
    render(<GameFinishedOverlay />);

    expect(screen.getByText('3')).toBeInTheDocument();
  });

  it('closes the overlay after the 3-second countdown', () => {
    useGameStore.getState().showFinishedOverlay(RANKINGS);
    render(<GameFinishedOverlay />);

    act(() => {
      vi.advanceTimersByTime(3_000);
    });

    expect(useGameStore.getState().isGameFinishedOverlayOpen).toBe(false);
  });
});
