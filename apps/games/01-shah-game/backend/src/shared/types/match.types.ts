export interface MatchPlayerInfo {
  playerId: string;
  displayName: string;
  seatIndex: number;
}

export interface MatchState {
  id: string;
  roomCode: string;
  hostPlayerId: string;
  status: 'lobby' | 'in_progress' | 'finished';
  players: MatchPlayerInfo[];
  playerCount: number;
}
