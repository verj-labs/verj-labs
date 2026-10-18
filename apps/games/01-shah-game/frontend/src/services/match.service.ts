import { type MatchState } from '@/types/match';
import api from './api';

export interface CreateMatchResponse {
  matchId: string;
  roomCode: string;
  match: MatchState;
}

export async function createMatch(): Promise<CreateMatchResponse> {
  const { data } = await api.post<CreateMatchResponse>('/match');
  return data;
}

export async function joinMatch(roomCode: string): Promise<MatchState> {
  const { data } = await api.post<MatchState>('/match/join', { roomCode });
  return data;
}

export async function getMatch(matchId: string): Promise<MatchState> {
  const { data } = await api.get<MatchState>(`/match/${matchId}`);
  return data;
}

export async function leaveMatch(matchId: string): Promise<void> {
  await api.delete(`/match/${matchId}/leave`);
}

export async function startMatch(matchId: string): Promise<MatchState> {
  const { data } = await api.post<MatchState>(`/match/${matchId}/start`);
  return data;
}
