/**
 * ResultsPage
 *
 * Shown after the host ends the match (match:finished event fires and all
 * clients navigate here).  Fetches the full match summary from
 * GET /match/:matchId/summary and displays aggregate standings + per-game
 * rankings in an animated layout.
 *
 * If the summary is already in matchStore (set by the match:finished event),
 * the standings are displayed immediately without a spinner delay.
 */
import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { motion } from 'framer-motion';
import api from '@/services/api';
import { logger } from '@/lib/logger';
import { useMatchStore } from '@/store/matchStore';
import { useSessionStore } from '@/store/sessionStore';
import { LoadingSpinner } from '@/components/ui/LoadingSpinner';

// ─── Types ────────────────────────────────────────────────────────────────────

interface PlayerMatchStat {
  playerId: string;
  displayName: string;
  gamesPlayed: number;
  wins: number;
  averageRank: number;
  bestFinish: number;
}

interface GameSummary {
  gameId: string;
  gameNumber: number;
  rankings: Array<{ playerId: string; displayName: string; rank: number }>;
}

interface MatchSummary {
  matchId: string;
  roomCode: string;
  status: string;
  totalGames?: number;
  players: Array<{ id: string; displayName: string; seatIndex: number }>;
  aggregate: PlayerMatchStat[];
  games: GameSummary[];
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function medal(rank: number): string {
  if (rank === 1) return '🥇';
  if (rank === 2) return '🥈';
  if (rank === 3) return '🥉';
  return `${rank}.`;
}

// ─── Component ────────────────────────────────────────────────────────────────

export default function ResultsPage() {
  const { matchId } = useParams<{ matchId: string }>();
  const navigate = useNavigate();

  const localPlayerId = useSessionStore((s) => s.player?.id);
  const matchFinished = useMatchStore((s) => s.matchFinished);
  const clearMatch = useMatchStore((s) => s.clearMatch);

  const [summary, setSummary] = useState<MatchSummary | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!matchId) return;

    // If we already have the finished payload from the socket event, derive
    // a lightweight summary from it while the full fetch completes.
    if (matchFinished && matchFinished.matchId === matchId) {
      setSummary({
        matchId: matchFinished.matchId,
        roomCode: '',
        status: 'finished',
        totalGames: matchFinished.totalGames,
        players: matchFinished.standings.map((s) => ({
          id: s.playerId,
          displayName: s.displayName,
          seatIndex: 0,
        })),
        aggregate: matchFinished.standings,
        games: [],
      });
    }

    // Fetch the full summary from the API (authoritative data)
    api
      .get<MatchSummary>(`/match/${matchId}/summary`)
      .then((res) => {
        setSummary(res.data);
      })
      .catch((err: unknown) => {
        logger.error('[ResultsPage] Failed to fetch match summary:', err);
        setError('Could not load match results. Please try again.');
      });
  }, [matchId, matchFinished]);

  function handlePlayAgain(): void {
    clearMatch();
    void navigate('/lobby', { replace: true });
  }

  // ── Loading ──────────────────────────────────────────────────────────────────

  if (!summary && !error) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-background">
        <LoadingSpinner size="lg" />
        <p className="text-muted-foreground">Loading results…</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-background">
        <p className="text-destructive">{error}</p>
        <button
          onClick={handlePlayAgain}
          className="rounded-lg bg-primary px-6 py-2 text-sm font-medium text-primary-foreground"
        >
          Back to Lobby
        </button>
      </div>
    );
  }

  const gamesPlayed = summary!.games.length > 0 ? summary!.games.length : (summary!.totalGames ?? 0);

  // ── Render ───────────────────────────────────────────────────────────────────

  return (
    <div className="min-h-screen bg-background px-4 py-10">
      <div className="mx-auto max-w-2xl space-y-8">

        {/* Header */}
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ duration: 0.4 }}
          className="text-center"
        >
          <h1 className="text-3xl font-bold text-foreground">Match Results</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            {gamesPlayed} {gamesPlayed === 1 ? 'game' : 'games'} played
            {summary!.roomCode ? ` · Room ${summary!.roomCode}` : ''}
          </p>
        </motion.div>

        {/* Overall standings */}
        <motion.section
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ duration: 0.4, delay: 0.1 }}
        >
          <h2 className="mb-3 text-lg font-semibold text-foreground">
            Final Standings
          </h2>
          <ul className="space-y-2" data-testid="final-standings">
            {summary!.aggregate.map((stat, i) => (
              <motion.li
                key={stat.playerId}
                initial={{ x: -20, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: 0.15 + i * 0.07 }}
                className={[
                  'flex items-center gap-4 rounded-xl border px-4 py-3',
                  stat.playerId === localPlayerId
                    ? 'border-primary/40 bg-primary/5'
                    : 'border-border bg-muted/30',
                ].join(' ')}
                data-testid={`standing-row-${stat.playerId}`}
              >
                <span className="w-8 text-center text-xl">{medal(i + 1)}</span>

                <div className="flex-1">
                  <p
                    className={[
                      'font-medium',
                      stat.playerId === localPlayerId
                        ? 'text-primary'
                        : 'text-foreground',
                    ].join(' ')}
                  >
                    {stat.displayName}
                    {stat.playerId === localPlayerId && (
                      <span className="ml-1 text-xs text-muted-foreground">(you)</span>
                    )}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {stat.wins} win{stat.wins !== 1 ? 's' : ''} · avg rank{' '}
                    {stat.averageRank.toFixed(1)} · best finish {stat.bestFinish}
                  </p>
                </div>
              </motion.li>
            ))}
          </ul>
        </motion.section>

        {/* Per-game breakdown */}
        {summary!.games.length > 0 && (
          <motion.section
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ duration: 0.4, delay: 0.3 }}
          >
            <h2 className="mb-3 text-lg font-semibold text-foreground">
              Game-by-Game
            </h2>
            <div className="space-y-3">
              {summary!.games.map((game) => (
                <div
                  key={game.gameId}
                  className="rounded-xl border border-border bg-muted/20 px-4 py-3"
                  data-testid={`game-breakdown-${game.gameNumber}`}
                >
                  <p className="mb-2 text-sm font-medium text-foreground">
                    Game {game.gameNumber}
                  </p>
                  <ol className="space-y-1">
                    {game.rankings
                      .slice()
                      .sort((a, b) => a.rank - b.rank)
                      .map((entry) => (
                        <li
                          key={entry.playerId}
                          className={[
                            'flex items-center gap-2 text-sm',
                            entry.playerId === localPlayerId
                              ? 'font-medium text-primary'
                              : 'text-muted-foreground',
                          ].join(' ')}
                        >
                          <span className="w-5 text-center">{medal(entry.rank)}</span>
                          {entry.displayName}
                          {entry.playerId === localPlayerId && (
                            <span className="text-xs text-muted-foreground">(you)</span>
                          )}
                        </li>
                      ))}
                  </ol>
                </div>
              ))}
            </div>
          </motion.section>
        )}

        {/* Back to lobby */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
          className="flex justify-center"
        >
          <button
            onClick={handlePlayAgain}
            className="rounded-xl bg-primary px-8 py-3 font-semibold text-primary-foreground shadow-md transition-opacity hover:opacity-90"
            data-testid="back-to-lobby-button"
          >
            Back to Lobby
          </button>
        </motion.div>
      </div>
    </div>
  );
}
