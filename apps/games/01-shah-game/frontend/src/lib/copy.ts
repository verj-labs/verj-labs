/**
 * Shah Exchange — UI copy constants.
 * All user-facing strings live here. Import and use COPY.* instead of
 * hardcoding labels in JSX — keeps the friend-group voice consistent and
 * makes future copy tweaks a one-file change.
 *
 * Voice rules:
 *  - Short and punchy. Max 4-5 words per label.
 *  - Emoji: max 1 per label, purposeful only.
 *  - No ALL CAPS in labels (event overlays are separate).
 *  - No "please" / "sorry" — use playful alternatives.
 */

export const COPY = {
  // ── Navigation / CTAs ────────────────────────────────────────────
  createRoom: 'Start the Madness',
  joinRoom: 'Jump In',
  roomCodeLabel: 'Code',
  viewHistory: 'Match history',
  backToLobby: 'Back',
  startGame: 'Start game',

  // ── Landing / auth ───────────────────────────────────────────────
  landingTitle: 'Shah Exchange',
  landingSubtitle: 'Pick a name and jump in',
  displayNameLabel: 'Your name',
  displayNamePlaceholder: 'e.g. Alice',
  enterGame: 'Enter Game',
  entering: 'Entering…',
  roomCodePlaceholder: 'e.g. AB3Z',

  // ── Lobby headings ────────────────────────────────────────────────
  createRoomHeading: 'Start a room',
  createRoomBody: 'New game, fresh chaos. Share the code with friends.',
  joinRoomHeading: 'Join a room',

  // ── Waiting room ─────────────────────────────────────────────────
  waitingForPlayers: (needed: number): string =>
    `Need ${needed} more chaos agent${needed !== 1 ? 's' : ''}`,
  playerThinking: (name: string): string => `${name} is plotting…`,
  playerPassed: (name: string): string => `${name} passed 💤`,
  waitingForHost: 'Waiting for host to start…',

  // ── Game actions ─────────────────────────────────────────────────
  yourTurn: 'Your move 👀',
  notYourTurn: 'Wait for your turn',
  play: 'Play',
  playCount: (n: number): string => `Play (${n})`,
  pass: 'Pass',

  // ── Error / feedback ──────────────────────────────────────────────
  invalidPlay: "Can't do that",
  genericError: 'Something broke 💀',
  connectionLost: 'Connection lost — reconnecting…',
  connecting: 'Loading the chaos…',
  roomNotFound: 'Room not found. Check the code.',
  roomFull: 'This room is full.',
  alreadyInRoom: "You're already in this room.",
  gameAlreadyStarted: 'Game already started.',
  tryAgain: 'Try again',

  // ── Game state / results ─────────────────────────────────────────
  gameOver: "That's a wrap 🎬",
  roundDone: 'Round done!',
  roundWins: (name: string): string => `${name} wins the round!`,
  matchWins: (name: string): string => `${name} takes the match 👑`,
  youWonRound: 'You won the round 🎉',
  youLostRound: 'Better luck next round',
  shahTitle: 'Shah 👑',
  runtTitle: 'Runt 🦆',

  // ── Card exchange ────────────────────────────────────────────────
  exchangePhaseTitle: 'The Trade',
  exchangeSubtitle: 'Shah and Runt swap cards',

  // ── Event overlays ───────────────────────────────────────────────
  skipOverlay: 'SKIP!',
  resetOverlay: 'RESET!',
  skipPhrases: [
    'sit down 😭',
    'no turn for you',
    'get cooked',
    'skipped like a stone 🪨',
    'next time maybe 💅',
  ] as const,

  // ── Accessibility / ARIA ─────────────────────────────────────────
  cardFaceDown: 'card face down',
  cardLabel: (rank: string, suit: string): string => `${rank} of ${suit}`,
  seatEmpty: (n: number): string => `Empty seat ${n}`,
  hostLabel: 'Host',
} as const;

/** Pick a random skip phrase from the pool. */
export function randomSkipPhrase(): string {
  const idx = Math.floor(Math.random() * COPY.skipPhrases.length);
  return COPY.skipPhrases[idx];
}
