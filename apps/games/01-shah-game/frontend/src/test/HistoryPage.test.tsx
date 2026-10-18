import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { vi, describe, it, expect, beforeEach } from 'vitest';
import HistoryPage from '@/pages/HistoryPage';
import * as playerService from '@/services/player.service';
import { type MatchHistoryPage } from '@/services/player.service';

vi.mock('@/services/player.service');

const mockGetMatchHistory = vi.mocked(playerService.getMatchHistory);

function emptyPage(page = 1): MatchHistoryPage {
  return { total: 0, page, limit: 10, items: [] };
}

function buildPage(count: number, total?: number): MatchHistoryPage {
  return {
    total: total ?? count,
    page: 1,
    limit: 10,
    items: Array.from({ length: count }, (_, i) => ({
      matchId: `m${i}`,
      roomCode: `AB${String(i).padStart(2, '0')}`,
      playerCount: 4,
      gamesPlayed: 2,
      bestFinish: i === 0 ? 1 : null,
      status: 'finished' as const,
      createdAt: new Date(Date.now() - i * 3_600_000).toISOString(),
    })),
  };
}

function renderHistory() {
  return render(
    <MemoryRouter initialEntries={['/history']}>
      <Routes>
        <Route path="/history" element={<HistoryPage />} />
        <Route path="/lobby" element={<div>Lobby</div>} />
        <Route path="/results/:matchId" element={<div data-testid="results-page">Results</div>} />
      </Routes>
    </MemoryRouter>,
  );
}

describe('HistoryPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders loading skeletons while the API is in flight', () => {
    mockGetMatchHistory.mockReturnValue(new Promise(() => {})); // never resolves
    renderHistory();
    expect(screen.getAllByTestId('history-skeleton').length).toBeGreaterThan(0);
  });

  it('shows empty state for a player with no history', async () => {
    mockGetMatchHistory.mockResolvedValue(emptyPage());
    renderHistory();
    await waitFor(() =>
      expect(screen.getByTestId('history-empty')).toBeInTheDocument(),
    );
  });

  it('renders match cards for a player with history', async () => {
    mockGetMatchHistory.mockResolvedValue(buildPage(3));
    renderHistory();
    await waitFor(() =>
      expect(screen.getByTestId('history-item-m0')).toBeInTheDocument(),
    );
    expect(screen.getByTestId('history-item-m1')).toBeInTheDocument();
    expect(screen.getByTestId('history-item-m2')).toBeInTheDocument();
  });

  it('shows "Show more" button when more pages exist', async () => {
    mockGetMatchHistory.mockResolvedValue(buildPage(10, 15));
    renderHistory();
    await waitFor(() =>
      expect(screen.getByTestId('show-more-button')).toBeInTheDocument(),
    );
    expect(screen.getByTestId('show-more-button')).toHaveTextContent('5 remaining');
  });

  it('hides "Show more" when all items are loaded', async () => {
    mockGetMatchHistory.mockResolvedValue(buildPage(3, 3));
    renderHistory();
    await waitFor(() =>
      expect(screen.getByTestId('history-item-m0')).toBeInTheDocument(),
    );
    expect(screen.queryByTestId('show-more-button')).not.toBeInTheDocument();
  });

  it('appends items when "Show more" is clicked', async () => {
    const page1 = buildPage(10, 12);
    const page2: MatchHistoryPage = {
      total: 12,
      page: 2,
      limit: 10,
      items: [
        { matchId: 'extra-0', roomCode: 'XX00', playerCount: 4, gamesPlayed: 1, bestFinish: 2, status: 'finished', createdAt: new Date().toISOString() },
        { matchId: 'extra-1', roomCode: 'XX01', playerCount: 4, gamesPlayed: 1, bestFinish: 3, status: 'finished', createdAt: new Date().toISOString() },
      ],
    };
    mockGetMatchHistory
      .mockResolvedValueOnce(page1)
      .mockResolvedValueOnce(page2);

    const user = userEvent.setup();
    renderHistory();

    await waitFor(() =>
      expect(screen.getByTestId('show-more-button')).toBeInTheDocument(),
    );
    await user.click(screen.getByTestId('show-more-button'));

    await waitFor(() =>
      expect(screen.getByTestId('history-item-extra-0')).toBeInTheDocument(),
    );
    expect(screen.getByTestId('history-item-extra-1')).toBeInTheDocument();
    // Original items still present
    expect(screen.getByTestId('history-item-m0')).toBeInTheDocument();
  });

  it('navigates to results page when a match card is clicked', async () => {
    mockGetMatchHistory.mockResolvedValue(buildPage(1));
    const user = userEvent.setup();
    renderHistory();

    await waitFor(() =>
      expect(screen.getByTestId('history-item-m0')).toBeInTheDocument(),
    );
    await user.click(screen.getByTestId('history-item-m0'));

    await waitFor(() =>
      expect(screen.getByTestId('results-page')).toBeInTheDocument(),
    );
  });

  it('navigates to lobby when Back is clicked', async () => {
    mockGetMatchHistory.mockResolvedValue(emptyPage());
    const user = userEvent.setup();
    renderHistory();

    await waitFor(() =>
      expect(screen.getByTestId('history-empty')).toBeInTheDocument(),
    );
    await user.click(screen.getByLabelText('Back to lobby'));

    expect(screen.getByText('Lobby')).toBeInTheDocument();
  });

  it('shows error message when the API fails', async () => {
    mockGetMatchHistory.mockRejectedValue(new Error('Network error'));
    renderHistory();
    await waitFor(() =>
      expect(screen.getByRole('alert')).toBeInTheDocument(),
    );
    expect(screen.getByRole('alert')).toHaveTextContent('Failed to load');
  });
});
