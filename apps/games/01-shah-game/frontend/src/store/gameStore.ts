import { create } from 'zustand';
import { type Card } from '@/types/card';
import { type GameStateView } from '@/types/game-state';
import { type ExchangeSummaryPayload } from '@/types/socket-events';

// ─── Types ────────────────────────────────────────────────────────────────────

type RankingEntry = { playerId: string; displayName: string; rank: number };

interface GameStoreState {
  gameState: GameStateView | null;
  localPlayerId: string | null;
  selectedCards: Card[];
  isActionPending: boolean;
  lastActionError: string | null;
  isDisconnected: boolean;
  // ── Overlay / exchange state ──────────────────────────────────────────────
  gameFinishedRankings: RankingEntry[] | null;
  isGameFinishedOverlayOpen: boolean;
  exchangeSummary: ExchangeSummaryPayload | null;
  isExchangeViewOpen: boolean;
  // ── Animation triggers ───────────────────────────────────────────────────
  /** Id of the player who was most recently skipped; null when no skip pending */
  skippedPlayerId: string | null;
  /** True while the pile-reset scatter animation should play */
  pileResetPending: boolean;
}

interface GameStoreActions {
  setGameState: (state: GameStateView) => void;
  setLocalPlayerId: (id: string) => void;
  toggleCardSelection: (card: Card) => void;
  clearSelection: () => void;
  setActionPending: (pending: boolean) => void;
  setActionError: (error: string | null) => void;
  setDisconnected: (disconnected: boolean) => void;
  clearGame: () => void;
  // ── Overlay / exchange actions ────────────────────────────────────────────
  showFinishedOverlay: (rankings: RankingEntry[]) => void;
  closeFinishedOverlay: () => void;
  showExchangeView: (summary: ExchangeSummaryPayload) => void;
  closeExchangeView: () => void;
  // ── Animation actions ────────────────────────────────────────────────────
  setSkippedPlayer: (playerId: string) => void;
  clearSkippedPlayer: () => void;
  setPileResetPending: (pending: boolean) => void;
}

type GameStore = GameStoreState & GameStoreActions;

// ─── Selectors ────────────────────────────────────────────────────────────────

/** True when it is this client's turn */
export function selectIsMyTurn(state: GameStoreState): boolean {
  const { gameState, localPlayerId } = state;
  if (!gameState || !localPlayerId) return false;
  const activePlayer = gameState.players[gameState.activePlayerIndex];
  return activePlayer?.id === localPlayerId;
}

/** The local player's PlayerView entry (for hand count, rank, etc.) */
export function selectLocalPlayerView(state: GameStoreState) {
  const { gameState, localPlayerId } = state;
  if (!gameState || !localPlayerId) return null;
  return gameState.players.find((p) => p.id === localPlayerId) ?? null;
}

/** True if a card is currently selected */
export function selectIsCardSelected(card: Card) {
  return (state: GameStoreState): boolean =>
    state.selectedCards.some((c) => c.rank === card.rank && c.suit === card.suit);
}

// ─── Initial state ────────────────────────────────────────────────────────────

const INITIAL_STATE: GameStoreState = {
  gameState: null,
  localPlayerId: null,
  selectedCards: [],
  isActionPending: false,
  lastActionError: null,
  isDisconnected: false,
  gameFinishedRankings: null,
  isGameFinishedOverlayOpen: false,
  exchangeSummary: null,
  isExchangeViewOpen: false,
  skippedPlayerId: null,
  pileResetPending: false,
};

// ─── Store ────────────────────────────────────────────────────────────────────

export const useGameStore = create<GameStore>((set) => ({
  ...INITIAL_STATE,

  setGameState: (gameState) =>
    set((prev) => {
      // Clear selected cards when the round or active player changes so
      // stale selections don't persist across turns
      const roundChanged =
        prev.gameState != null &&
        prev.gameState.currentRound.pile.topPlay?.cards[0]?.rank !==
          gameState.currentRound.pile.topPlay?.cards[0]?.rank;
      const turnChanged =
        prev.gameState != null &&
        prev.gameState.activePlayerIndex !== gameState.activePlayerIndex;
      return {
        gameState,
        lastActionError: null,
        ...(roundChanged || turnChanged ? { selectedCards: [] } : {}),
      };
    }),

  setLocalPlayerId: (localPlayerId) => set({ localPlayerId }),

  toggleCardSelection: (card) =>
    set((state) => {
      const isSelected = state.selectedCards.some(
        (c) => c.rank === card.rank && c.suit === card.suit,
      );
      return {
        selectedCards: isSelected
          ? state.selectedCards.filter((c) => !(c.rank === card.rank && c.suit === card.suit))
          : [...state.selectedCards, card],
      };
    }),

  clearSelection: () => set({ selectedCards: [] }),

  setActionPending: (isActionPending) => set({ isActionPending }),

  setActionError: (lastActionError) => set({ lastActionError }),

  setDisconnected: (isDisconnected) => set({ isDisconnected }),

  clearGame: () => set(INITIAL_STATE),

  showFinishedOverlay: (rankings) =>
    set({ gameFinishedRankings: rankings, isGameFinishedOverlayOpen: true }),

  closeFinishedOverlay: () => set({ isGameFinishedOverlayOpen: false }),

  showExchangeView: (summary) =>
    set({ exchangeSummary: summary, isExchangeViewOpen: true }),

  closeExchangeView: () => set({ isExchangeViewOpen: false }),

  setSkippedPlayer: (playerId) => set({ skippedPlayerId: playerId }),

  clearSkippedPlayer: () => set({ skippedPlayerId: null }),

  setPileResetPending: (pending) => set({ pileResetPending: pending }),
}));
