import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';
import {
  getMatchHistory,
  type MatchHistoryItem,
} from '@/services/player.service';

const PAGE_LIMIT = 10;

// ─── Relative time helper ────────────────────────────────────────────────────

function relativeTime(isoDate: string): string {
  const diff = Date.now() - new Date(isoDate).getTime();
  const minutes = Math.floor(diff / 60_000);
  if (minutes < 1) return 'just now';
  if (minutes < 60) return `${minutes} minute${minutes !== 1 ? 's' : ''} ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} hour${hours !== 1 ? 's' : ''} ago`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days} day${days !== 1 ? 's' : ''} ago`;
  const months = Math.floor(days / 30);
  return `${months} month${months !== 1 ? 's' : ''} ago`;
}

function bestFinishLabel(rank: number | null): string {
  if (rank === null) return '—';
  const suffix = rank === 1 ? 'st' : rank === 2 ? 'nd' : rank === 3 ? 'rd' : 'th';
  return `${rank}${suffix}`;
}

// ─── Match Card ──────────────────────────────────────────────────────────────

function MatchCard({
  item,
  onClick,
}: {
  item: MatchHistoryItem;
  onClick: () => void;
}) {
  const isFinished = item.status === 'finished';

  return (
    <button
      type="button"
      data-testid={`history-item-${item.matchId}`}
      onClick={onClick}
      className="w-full text-left bg-[var(--color-surface)] border border-[var(--color-border)] rounded-xl p-4 shadow hover:bg-[var(--color-bg-1)] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-neon-lime)]"
    >
      <div className="flex items-start justify-between gap-3">
        {/* Left: room code + date */}
        <div className="space-y-0.5">
          <p className="text-[var(--color-electric-yellow)] font-mono font-bold tracking-widest text-lg leading-none">
            {item.roomCode}
          </p>
          <p className="text-muted-foreground text-xs">{relativeTime(item.createdAt)}</p>
        </div>

        {/* Right: status badge */}
        <span
          className={`shrink-0 text-xs font-medium px-2 py-0.5 rounded-full ${
            isFinished
              ? 'bg-[var(--color-border)] text-muted-foreground'
              : 'bg-[var(--color-electric-yellow)]/10 text-[var(--color-electric-yellow)]'
          }`}
        >
          {isFinished ? 'Finished' : item.status === 'in_progress' ? 'In progress' : 'Lobby'}
        </span>
      </div>

      {/* Stats row */}
      <div className="mt-3 flex gap-6 text-sm">
        <div>
          <p className="text-muted-foreground text-xs uppercase tracking-wide">Players</p>
          <p className="text-foreground font-semibold">{item.playerCount}</p>
        </div>
        <div>
          <p className="text-muted-foreground text-xs uppercase tracking-wide">Games</p>
          <p className="text-foreground font-semibold">{item.gamesPlayed}</p>
        </div>
        <div>
          <p className="text-muted-foreground text-xs uppercase tracking-wide">Best finish</p>
          <p
            className={`font-semibold ${item.bestFinish === 1 ? 'text-[var(--color-electric-yellow)]' : 'text-foreground'}`}
          >
            {bestFinishLabel(item.bestFinish)}
          </p>
        </div>
      </div>
    </button>
  );
}

// ─── Skeleton ────────────────────────────────────────────────────────────────

function MatchCardSkeleton() {
  return (
    <div
      data-testid="history-skeleton"
      className="w-full bg-[var(--color-surface)] border border-[var(--color-border)] rounded-xl p-4 animate-pulse space-y-3"
    >
      <div className="flex justify-between">
        <div className="h-6 w-20 bg-[var(--color-border)] rounded" />
        <div className="h-5 w-16 bg-[var(--color-border)] rounded-full" />
      </div>
      <div className="flex gap-6">
        <div className="h-8 w-12 bg-[var(--color-border)] rounded" />
        <div className="h-8 w-12 bg-[var(--color-border)] rounded" />
        <div className="h-8 w-16 bg-[var(--color-border)] rounded" />
      </div>
    </div>
  );
}

// ─── Page ────────────────────────────────────────────────────────────────────

export default function HistoryPage() {
  const navigate = useNavigate();

  const [items, setItems] = useState<MatchHistoryItem[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [isLoading, setIsLoading] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Initial fetch
  useEffect(() => {
    setIsLoading(true);
    getMatchHistory(1, PAGE_LIMIT)
      .then((result) => {
        setItems(result.items);
        setTotal(result.total);
        setPage(1);
      })
      .catch(() => setError('Failed to load match history.'))
      .finally(() => setIsLoading(false));
  }, []);

  async function handleShowMore(): Promise<void> {
    const nextPage = page + 1;
    setIsLoadingMore(true);
    try {
      const result = await getMatchHistory(nextPage, PAGE_LIMIT);
      setItems((prev) => [...prev, ...result.items]);
      setPage(nextPage);
    } catch {
      setError('Failed to load more matches.');
    } finally {
      setIsLoadingMore(false);
    }
  }

  const hasMore = items.length < total;

  return (
    <main className="min-h-screen bg-[var(--color-bg-0)] flex flex-col items-center p-4 pt-8 gap-6">
      {/* Header */}
      <div className="w-full max-w-sm flex items-center gap-3">
        <button
          type="button"
          onClick={() => void navigate('/lobby')}
          className="text-muted-foreground hover:text-foreground transition text-sm"
          aria-label="Back to lobby"
        >
          ← Back
        </button>
        <h1 className="text-foreground font-bold text-xl flex-1 text-center pr-8 font-[var(--font-heading)]">
          Match History
        </h1>
      </div>

      <div className="w-full max-w-sm space-y-3">
        {/* Loading skeletons */}
        {isLoading && (
          <>
            <MatchCardSkeleton />
            <MatchCardSkeleton />
            <MatchCardSkeleton />
          </>
        )}

        {/* Error state */}
        {!isLoading && error && (
          <p role="alert" className="text-red-300 text-sm text-center">
            {error}
          </p>
        )}

        {/* Empty state */}
        {!isLoading && !error && items.length === 0 && (
          <div
            data-testid="history-empty"
            className="bg-[var(--color-surface)] border border-[var(--color-border)] rounded-xl p-8 text-center space-y-4"
          >
            <p className="text-muted-foreground text-sm">No matches yet.</p>
            <Button
              variant="cta"
              onClick={() => void navigate('/lobby')}
            >
              Create a Room
            </Button>
          </div>
        )}

        {/* Match list */}
        {items.map((item) => (
          <MatchCard
            key={item.matchId}
            item={item}
            onClick={() => void navigate(`/results/${item.matchId}`)}
          />
        ))}

        {/* Show more */}
        {!isLoading && hasMore && (
          <Button
            data-testid="show-more-button"
            onClick={() => void handleShowMore()}
            disabled={isLoadingMore}
            variant="ghost"
            className="w-full text-muted-foreground hover:text-foreground hover:bg-[var(--color-surface)]"
          >
            {isLoadingMore ? (
              <span className="flex items-center gap-2">
                <LoadingSpinner size="sm" />
                Loading…
              </span>
            ) : (
              `Show more (${total - items.length} remaining)`
            )}
          </Button>
        )}
      </div>
    </main>
  );
}
