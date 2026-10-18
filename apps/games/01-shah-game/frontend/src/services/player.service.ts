import api from './api';

export interface MatchHistoryItem {
  matchId: string;
  roomCode: string;
  playerCount: number;
  gamesPlayed: number;
  bestFinish: number | null;
  status: 'lobby' | 'in_progress' | 'finished';
  createdAt: string;
}

export interface MatchHistoryPage {
  total: number;
  page: number;
  limit: number;
  items: MatchHistoryItem[];
}

export async function getMatchHistory(
  page = 1,
  limit = 10,
): Promise<MatchHistoryPage> {
  const { data } = await api.get<MatchHistoryPage>('/player/me/matches', {
    params: { page, limit },
  });
  return data;
}
