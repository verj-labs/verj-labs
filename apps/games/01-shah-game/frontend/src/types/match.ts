export interface MatchPlayerInfo {
  playerId: string;
  displayName: string;
  seatIndex: number;
}

export type MatchStatus = 'lobby' | 'in_progress' | 'finished';

export interface MatchState {
  id: string;
  roomCode: string;
  hostPlayerId: string;
  status: MatchStatus;
  players: MatchPlayerInfo[];
  playerCount: number;
}
