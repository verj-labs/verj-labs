import api from './api';
import { type Player } from '@/types/player';

export interface CreateSessionResponse {
  token: string;
  player: Player;
}

export interface MeResponse {
  player: Player;
  matchId: string | null;
}

export async function createSession(
  displayName: string,
): Promise<CreateSessionResponse> {
  const { data } = await api.post<CreateSessionResponse>('/auth/session', {
    displayName,
  });
  return data;
}

export async function getMe(): Promise<MeResponse> {
  const { data } = await api.get<MeResponse>('/auth/me');
  return data;
}

export async function deleteSession(): Promise<void> {
  await api.delete('/auth/session');
}
