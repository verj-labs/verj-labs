import { Injectable } from '@nestjs/common';
import { type Card } from '../shared/types/card.types';
import {
  type EngineResult,
  type GameEvent,
  type PlayIntent,
} from '../shared/types/events.types';
import { type GameState, type Player } from '../shared/types/game-state.types';
import { RulesService } from './rules.service';
import { getNextActivePlayerIndex } from './turn.utils';

@Injectable()
export class GameEngineService {
  constructor(private readonly rulesService: RulesService) {}

  // ─── Public entry point ──────────────────────────────────────────────────────

  /**
   * Process a player intent and return the new game state plus emitted events.
   *
   * This function is **pure** with respect to the caller: the input `state` is
   * never mutated.  A deep clone is made before any field changes.
   */
  processIntent(state: GameState, intent: PlayIntent): EngineResult {
    // Deep-clone the entire state so we never mutate the input.
    const s: GameState = JSON.parse(JSON.stringify(state)) as GameState;
    const events: GameEvent[] = [];

    if (intent.type === 'pass') {
      // Verify it is actually this player's turn (same guard as play intents)
      const activePlayer = s.players[s.activePlayerIndex];
      if (activePlayer.id !== intent.playerId) {
        return { newState: state, events: [], error: 'It is not your turn.' };
      }
      return this.handlePass(s, events, state);
    }

    // Validate before any mutation
    const validation = this.rulesService.validatePlay(s, intent);
    if (!validation.valid) {
      return { newState: state, events: [], error: validation.reason };
    }

    const cards = intent.cards!;

    if (validation.isReset) {
      return this.handleReset(s, events, cards);
    }

    return this.handlePlay(s, events, cards, intent.playerId);
  }

  // ─── Pass branch (T-035) ─────────────────────────────────────────────────────

  private handlePass(
    s: GameState,
    events: GameEvent[],
    originalState: GameState,
  ): EngineResult {
    const activePlayer = s.players[s.activePlayerIndex];

    s.currentRound.consecutivePassCount++;
    s.currentRound.passedThisRound = [
      ...s.currentRound.passedThisRound,
      activePlayer.id,
    ];

    events.push({
      type: 'PLAYER_PASSED',
      payload: { playerId: activePlayer.id },
    });

    // Active players = players who have not yet finished
    const activeCount = s.players.filter((p) => !p.isFinished).length;

    // Round ends when all OTHER active players have passed consecutively.
    // The last player who played does not need to pass (they own the pile).
    // If nobody has played yet (round just started) or the last player who
    // played has since finished, ALL active players must pass.
    const lastPlayer = s.currentRound.lastPlayerId
      ? s.players.find((p) => p.id === s.currentRound.lastPlayerId)
      : null;
    const lastPlayerStillActive = lastPlayer != null && !lastPlayer.isFinished;
    const threshold = lastPlayerStillActive ? activeCount - 1 : activeCount;

    if (s.currentRound.consecutivePassCount >= threshold) {
      return this.endRound(s, events, originalState);
    }

    // Otherwise just advance the turn
    const nextIdx = getNextActivePlayerIndex(s, s.activePlayerIndex);
    s.activePlayerIndex = nextIdx;
    events.push({
      type: 'TURN_ADVANCED',
      payload: { nextPlayerIndex: nextIdx },
    });

    return { newState: s, events };
  }

  // ─── Normal play branch (T-036) ──────────────────────────────────────────────

  private handlePlay(
    s: GameState,
    events: GameEvent[],
    cards: Card[],
    playerId: string,
  ): EngineResult {
    const player = s.players[s.activePlayerIndex];
    const round = s.currentRound;
    const currentPilePlay = round.pile.topPlay;
    const playRank = cards[0].rank;

    // Determine if this play matches the existing pile rank (skip rule)
    const isSameRank =
      currentPilePlay !== null && currentPilePlay.cards[0].rank === playRank;

    // Remove played cards from hand
    this.removeCardsFromHand(player, cards);

    // Update pile
    const play = { cards, playerId, isReset: false };
    round.pile.topPlay = play;
    round.pile.history.push(play);
    round.consecutivePassCount = 0;
    round.lastPlayerId = playerId;
    round.passedThisRound = [];

    events.push({ type: 'PILE_UPDATED', payload: { play } });

    // Detect finish
    this.checkAndMarkFinished(s, player, events);

    // Check if all players are finished → game over
    if (this.isGameFinished(s)) {
      s.status = 'finished';
      events.push({
        type: 'GAME_FINISHED',
        payload: { finishedPlayers: s.finishedPlayers },
      });
      return { newState: s, events };
    }

    // Advance turn (skip the next player if same rank was played)
    if (isSameRank) {
      const skippedIdx = getNextActivePlayerIndex(s, s.activePlayerIndex, 0);
      round.skippedPlayerIndex = skippedIdx;
      events.push({
        type: 'PLAYER_SKIPPED',
        payload: { skippedPlayerIndex: skippedIdx },
      });
      // Advance past the skipped slot regardless of whether the current player finished
      const nextIdx = getNextActivePlayerIndex(s, s.activePlayerIndex, 1);
      s.activePlayerIndex = nextIdx >= 0 ? nextIdx : s.activePlayerIndex;
    } else {
      const nextIdx = getNextActivePlayerIndex(s, s.activePlayerIndex, 0);
      s.activePlayerIndex = nextIdx >= 0 ? nextIdx : s.activePlayerIndex;
    }

    events.push({
      type: 'TURN_ADVANCED',
      payload: { nextPlayerIndex: s.activePlayerIndex },
    });

    return { newState: s, events };
  }

  // ─── Reset branch (T-037) ────────────────────────────────────────────────────

  private handleReset(
    s: GameState,
    events: GameEvent[],
    cards: Card[],
  ): EngineResult {
    const player = s.players[s.activePlayerIndex];
    const playerId = player.id;

    // Remove the 2-cards from hand
    this.removeCardsFromHand(player, cards);

    // Clear the pile
    s.currentRound.pile.topPlay = null;
    s.currentRound.pile.history = [];
    s.currentRound.consecutivePassCount = 0;
    // lastPlayerId: the resetter "holds" the pile for the next play
    s.currentRound.lastPlayerId = playerId;
    s.currentRound.passedThisRound = [];

    const play = { cards, playerId, isReset: true };
    events.push({ type: 'PILE_RESET', payload: { play } });

    // Check if the player used their last cards for the reset
    const didFinish = this.checkAndMarkFinished(s, player, events);
    if (this.isGameFinished(s)) {
      s.status = 'finished';
      events.push({
        type: 'GAME_FINISHED',
        payload: { finishedPlayers: s.finishedPlayers },
      });
      return { newState: s, events };
    }

    // If the player finished via this reset, advance to the next active player.
    // Otherwise the same player continues (turn extension rule).
    if (didFinish) {
      const nextIdx = getNextActivePlayerIndex(s, s.activePlayerIndex);
      s.activePlayerIndex = nextIdx;
      events.push({
        type: 'TURN_ADVANCED',
        payload: { nextPlayerIndex: nextIdx },
      });
    }

    return { newState: s, events };
  }

  // ─── Round end helper ────────────────────────────────────────────────────────

  private endRound(
    s: GameState,
    events: GameEvent[],
    _originalState: GameState,
  ): EngineResult {
    // Capture the round winner BEFORE clearing round data
    const lastPlayerId = s.currentRound.lastPlayerId;

    // Emit the event with the CURRENT round number (before incrementing)
    const endedRoundNumber = s.roundNumber;

    // Clear the pile and round tracking
    s.currentRound.pile.topPlay = null;
    s.currentRound.pile.history = [];
    s.currentRound.consecutivePassCount = 0;
    s.currentRound.passedThisRound = [];
    s.currentRound.lastPlayerId = null;

    // Track round progression
    s.roundNumber++;

    // The last player who played wins the round and starts the next one.
    if (lastPlayerId !== null) {
      const idx = s.players.findIndex((p) => p.id === lastPlayerId);
      if (idx !== -1) {
        // If that player has since finished, advance to the next active player
        s.activePlayerIndex = s.players[idx].isFinished
          ? getNextActivePlayerIndex(s, idx)
          : idx;
      }
    }

    events.push({
      type: 'ROUND_ENDED',
      payload: {
        nextPlayerIndex: s.activePlayerIndex,
        endedRoundNumber,
      },
    });

    return { newState: s, events };
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  private removeCardsFromHand(player: Player, cards: Card[]): void {
    const toRemove = [...cards];
    player.hand = player.hand.filter((hCard) => {
      const idx = toRemove.findIndex(
        (c) => c.rank === hCard.rank && c.suit === hCard.suit,
      );
      if (idx !== -1) {
        toRemove.splice(idx, 1);
        return false;
      }
      return true;
    });
  }

  private checkAndMarkFinished(
    s: GameState,
    player: Player,
    events: GameEvent[],
  ): boolean {
    if (player.hand.length > 0 || player.isFinished) return false;

    player.isFinished = true;
    const rank = s.finishedPlayers.length + 1;
    player.finishRank = rank;
    s.finishedPlayers.push(player.id);

    events.push({
      type: 'PLAYER_FINISHED',
      payload: { playerId: player.id, finishRank: rank },
    });

    // Auto-finish the last remaining player (they get last place automatically)
    this.autoFinishLastPlayer(s, events);

    return true;
  }

  /**
   * When only one non-finished player remains, auto-rank them as last place.
   * Per GAME_RULES.md §5: "Last remaining player = last place."
   */
  private autoFinishLastPlayer(s: GameState, events: GameEvent[]): void {
    const remaining = s.players.filter((p) => !p.isFinished);
    if (remaining.length !== 1) return;

    const last = remaining[0];
    last.isFinished = true;
    const rank = s.finishedPlayers.length + 1;
    last.finishRank = rank;
    s.finishedPlayers.push(last.id);

    events.push({
      type: 'PLAYER_FINISHED',
      payload: { playerId: last.id, finishRank: rank },
    });
  }

  private isGameFinished(s: GameState): boolean {
    return s.players.every((p) => p.isFinished);
  }
}
