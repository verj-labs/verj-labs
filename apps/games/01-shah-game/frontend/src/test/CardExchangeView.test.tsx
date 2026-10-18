import { act, render, screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { CardExchangeView } from '@/features/game/CardExchangeView';
import { useGameStore } from '@/store/gameStore';
import type { ExchangeSummaryPayload } from '@/types/socket-events';

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
  useReducedMotion: () => false,
}));

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const EXCHANGE_SUMMARY: ExchangeSummaryPayload = {
  gameId: 'game-1',
  exchanges: [
    {
      giverId: 'p1',
      giverName: 'Alice',
      receiverId: 'p4',
      receiverName: 'Dave',
      cardsGiven: [
        { rank: '3', suit: 'spades' },
        { rank: '4', suit: 'clubs' },
      ],
    },
    {
      giverId: 'p4',
      giverName: 'Dave',
      receiverId: 'p1',
      receiverName: 'Alice',
      cardsGiven: [
        { rank: 'A', suit: 'hearts' },
        { rank: '2', suit: 'diamonds' },
      ],
    },
    {
      giverId: 'p2',
      giverName: 'Bob',
      receiverId: 'p3',
      receiverName: 'Carol',
      cardsGiven: [{ rank: '5', suit: 'spades' }],
    },
    {
      giverId: 'p3',
      giverName: 'Carol',
      receiverId: 'p2',
      receiverName: 'Bob',
      cardsGiven: [{ rank: 'K', suit: 'hearts' }],
    },
  ],
};

function resetStore() {
  useGameStore.getState().clearGame();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('CardExchangeView', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    resetStore();
  });

  afterEach(() => {
    vi.useRealTimers();
    resetStore();
  });

  it('renders nothing when the view is closed', () => {
    const { container } = render(<CardExchangeView />);
    expect(container).toBeEmptyDOMElement();
  });

  it('renders the exchange dialog when opened', () => {
    useGameStore.getState().showExchangeView(EXCHANGE_SUMMARY);
    render(<CardExchangeView />);

    expect(screen.getByRole('dialog')).toBeInTheDocument();
    expect(screen.getByText('Card Exchange')).toBeInTheDocument();
  });

  it('shows all exchange actions', () => {
    useGameStore.getState().showExchangeView(EXCHANGE_SUMMARY);
    render(<CardExchangeView />);

    // Alice and Dave each appear as giver in one row and receiver in another
    expect(screen.getAllByText('Alice')).toHaveLength(2);
    expect(screen.getAllByText('Dave')).toHaveLength(2);
    // Bob and Carol each appear twice (giver + receiver in the second pair)
    expect(screen.getAllByText('Bob')).toHaveLength(2);
    expect(screen.getAllByText('Carol')).toHaveLength(2);
  });

  it('shows card chips for each transferred card', () => {
    useGameStore.getState().showExchangeView(EXCHANGE_SUMMARY);
    render(<CardExchangeView />);

    expect(screen.getByText('3♠')).toBeInTheDocument();
    expect(screen.getByText('4♣')).toBeInTheDocument();
    expect(screen.getByText('A♥')).toBeInTheDocument();
    expect(screen.getByText('2♦')).toBeInTheDocument();
  });

  it('replaces player name with "You" for local player', () => {
    useGameStore.getState().setLocalPlayerId('p1');
    useGameStore.getState().showExchangeView(EXCHANGE_SUMMARY);
    render(<CardExchangeView />);

    // "You" appears for rows involving p1
    const youElements = screen.getAllByText('You');
    expect(youElements.length).toBeGreaterThanOrEqual(2);
  });

  it('shows a "you receive" badge when local player is the receiver', () => {
    useGameStore.getState().setLocalPlayerId('p1');
    useGameStore.getState().showExchangeView(EXCHANGE_SUMMARY);
    render(<CardExchangeView />);

    expect(screen.getByText('← you receive')).toBeInTheDocument();
  });

  it('shows a "you give" badge when local player is the giver', () => {
    useGameStore.getState().setLocalPlayerId('p1');
    useGameStore.getState().showExchangeView(EXCHANGE_SUMMARY);
    render(<CardExchangeView />);

    expect(screen.getByText('you give →')).toBeInTheDocument();
  });

  it('shows the initial countdown value', () => {
    useGameStore.getState().showExchangeView(EXCHANGE_SUMMARY);
    render(<CardExchangeView />);

    expect(screen.getByText('5s')).toBeInTheDocument();
  });

  it('decrements the countdown each second', () => {
    useGameStore.getState().showExchangeView(EXCHANGE_SUMMARY);
    render(<CardExchangeView />);

    act(() => vi.advanceTimersByTime(2_000));

    expect(screen.getByText('3s')).toBeInTheDocument();
  });
});
