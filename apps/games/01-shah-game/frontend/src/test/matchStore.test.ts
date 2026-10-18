import { beforeEach, describe, expect, it } from 'vitest';
import { useMatchStore } from '@/store/matchStore';
import { type MatchState } from '@/types/match';

const MATCH_STATE: MatchState = {
  id: 'match-1',
  roomCode: 'ABCD',
  hostPlayerId: 'player-1',
  status: 'lobby',
  players: [
    { playerId: 'player-1', displayName: 'Alice', seatIndex: 0 },
    { playerId: 'player-2', displayName: 'Bob', seatIndex: 1 },
  ],
  playerCount: 2,
};

function resetStore() {
  useMatchStore.getState().clearMatch();
}

describe('matchStore', () => {
  beforeEach(() => {
    resetStore();
  });

  it('starts with all null / empty values', () => {
    const s = useMatchStore.getState();
    expect(s.matchId).toBeNull();
    expect(s.roomCode).toBeNull();
    expect(s.hostPlayerId).toBeNull();
    expect(s.players).toEqual([]);
    expect(s.status).toBeNull();
    expect(s.isLoading).toBe(false);
  });

  it('setMatch hydrates all fields from MatchState', () => {
    useMatchStore.getState().setMatch(MATCH_STATE);
    const s = useMatchStore.getState();
    expect(s.matchId).toBe('match-1');
    expect(s.roomCode).toBe('ABCD');
    expect(s.hostPlayerId).toBe('player-1');
    expect(s.status).toBe('lobby');
    expect(s.players).toHaveLength(2);
  });

  it('updatePlayers replaces the player list', () => {
    useMatchStore.getState().setMatch(MATCH_STATE);
    const newPlayers = [
      { playerId: 'player-3', displayName: 'Carol', seatIndex: 2 },
    ];
    useMatchStore.getState().updatePlayers(newPlayers);
    expect(useMatchStore.getState().players).toHaveLength(1);
    expect(useMatchStore.getState().players[0].displayName).toBe('Carol');
  });

  it('setHost updates only hostPlayerId', () => {
    useMatchStore.getState().setMatch(MATCH_STATE);
    useMatchStore.getState().setHost('player-2');
    const s = useMatchStore.getState();
    expect(s.hostPlayerId).toBe('player-2');
    // Other fields unchanged
    expect(s.matchId).toBe('match-1');
  });

  it('clearMatch resets store to initial state', () => {
    useMatchStore.getState().setMatch(MATCH_STATE);
    useMatchStore.getState().clearMatch();
    const s = useMatchStore.getState();
    expect(s.matchId).toBeNull();
    expect(s.roomCode).toBeNull();
    expect(s.players).toEqual([]);
  });

  it('setLoading toggles isLoading', () => {
    useMatchStore.getState().setLoading(true);
    expect(useMatchStore.getState().isLoading).toBe(true);
    useMatchStore.getState().setLoading(false);
    expect(useMatchStore.getState().isLoading).toBe(false);
  });
});
