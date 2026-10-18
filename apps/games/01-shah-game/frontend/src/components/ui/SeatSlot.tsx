import { type MatchPlayerInfo } from '@/types/match';
import { COPY } from '@/lib/copy';

export interface SeatSlotProps {
  seat: MatchPlayerInfo | null;
  seatIndex: number;
  isCurrentPlayer: boolean;
  isHost: boolean;
}

export function SeatSlot({ seat, seatIndex, isCurrentPlayer, isHost }: SeatSlotProps) {
  return (
    <div
      className={[
        'relative rounded-lg border-2 p-3 text-center space-y-1 transition-all',
        seat
          ? isCurrentPlayer
            ? 'border-[var(--color-neon-lime)] bg-[var(--color-surface)] neon-glow-lime'
            : 'border-[var(--color-border)] bg-[var(--color-surface)]'
          : 'border-[var(--color-border)] bg-[var(--color-bg-1)] opacity-40',
      ].join(' ')}
      aria-label={seat ? seat.displayName : COPY.seatEmpty(seatIndex + 1)}
    >
      {/* Seat number */}
      <span className="text-[var(--color-text-muted)] text-[10px] absolute top-1 left-2">
        {seatIndex + 1}
      </span>

      {/* Host crown */}
      {isHost && seat && (
        <span
          className="absolute top-1 right-2 text-[var(--color-electric-yellow)] text-xs"
          title={COPY.hostLabel}
          aria-label={COPY.hostLabel}
        >
          👑
        </span>
      )}

      {seat ? (
        <>
          {/* Avatar */}
          <div className="w-10 h-10 rounded-full bg-[var(--color-neon-lime)] flex items-center justify-center mx-auto text-[var(--color-bg-0)] font-bold text-sm select-none">
            {seat.displayName.charAt(0).toUpperCase()}
          </div>
          <p className="text-[var(--color-text-primary)] text-xs font-medium truncate">
            {seat.displayName}
          </p>
          {isCurrentPlayer && (
            <span className="text-[var(--color-neon-lime)] text-[10px]">
              (you)
            </span>
          )}
        </>
      ) : (
        <div className="flex flex-col items-center gap-1 py-1">
          <div className="w-10 h-10 rounded-full border-2 border-dashed border-[var(--color-border)] mx-auto" />
          <p className="text-[var(--color-text-muted)] text-xs">Empty</p>
        </div>
      )}
    </div>
  );
}
