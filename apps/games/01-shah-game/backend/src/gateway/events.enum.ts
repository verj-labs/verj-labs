/**
 * All WebSocket event name strings used between the Gateway and clients.
 *
 * NOTE: Keep in sync with frontend/src/types/socket-events.ts
 */

export const GameEvents = {
  // ── Server → Client ──────────────────────────────────────────────────────

  /** Game was initialised; each player receives their own projected view */
  GAME_STARTED: 'game:started',

  /** State changed after any intent (play, pass, reset); broadcast per-player */
  STATE_UPDATED: 'game:state_updated',

  /** The intent the player sent was invalid; sent to the requestor only */
  PLAY_REJECTED: 'game:play_rejected',

  /** All active players passed; pile was cleared */
  ROUND_ENDED: 'game:round_ended',

  /** A player was skipped because the same rank was played */
  PLAYER_SKIPPED: 'game:player_skipped',

  /** A 2 reset the pile */
  PILE_RESET: 'game:pile_reset',

  /** A player emptied their hand */
  PLAYER_FINISHED: 'game:player_finished',

  /** All players finished; game is over */
  GAME_FINISHED: 'game:finished',

  /** Post-game card exchange summary broadcast before next game starts */
  GAME_EXCHANGE: 'game:exchange',

  /** A player's socket disconnected */
  PLAYER_DISCONNECTED: 'player:disconnected',

  /** A disconnected player reconnected within the window */
  PLAYER_RECONNECTED: 'player:reconnected',

  // ── Server → Client (match lobby) ────────────────────────────────────────

  /** Match lobby state changed (player joined / left) */
  MATCH_UPDATED: 'match:updated',

  /** Hosting responsibility transferred */
  MATCH_HOST_CHANGED: 'match:host_changed',

  /** Match is fully over — aggregate results emitted */
  MATCH_FINISHED: 'match:finished',

  // ── Client → Server ───────────────────────────────────────────────────────

  /** Subscribe to a match room on connect */
  MATCH_SUBSCRIBE: 'match:subscribe',

  /** Play a set of cards */
  PLAY: 'game:play',

  /** Pass this turn */
  PASS: 'game:pass',
} as const;

export type GameEventValue = (typeof GameEvents)[keyof typeof GameEvents];
