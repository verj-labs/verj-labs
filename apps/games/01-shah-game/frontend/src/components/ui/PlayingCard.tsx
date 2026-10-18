import { cn } from '@/lib/utils';
import { type Card, isRedSuit, SUIT_SYMBOLS, type Rank, type Suit } from '@/types/card';

export interface PlayingCardProps {
  /** Convenience: pass a Card object directly; takes precedence over `rank`/`suit`. */
  card?: Card;
  rank?: Rank;
  suit?: Suit;
  faceDown?: boolean;
  selected?: boolean;
  disabled?: boolean;
  size?: 'sm' | 'md' | 'lg';
  onClick?: () => void;
  className?: string;
}

const SIZE_CLASSES = {
  sm: 'w-12 h-16 text-xs',
  md: 'w-16 h-24 text-sm',
  lg: 'w-20 h-32 text-base',
} as const;

const CORNER_SIZE_CLASSES = {
  sm: 'text-[10px] leading-none',
  md: 'text-xs leading-none',
  lg: 'text-sm leading-none',
} as const;

export function PlayingCard({
  card,
  rank: rankProp,
  suit: suitProp,
  faceDown = false,
  selected = false,
  disabled = false,
  size = 'md',
  onClick,
  className,
}: PlayingCardProps) {
  const rank = (card?.rank ?? rankProp)!;
  const suit = (card?.suit ?? suitProp)!;
  const red = isRedSuit(suit);
  const symbol = SUIT_SYMBOLS[suit];

  return (
    <button
      type="button"
      data-testid={!faceDown && rank && suit ? `card-${rank}${suit}` : undefined}
      aria-label={faceDown ? 'card face down' : `${rank} of ${suit}`}
      aria-pressed={selected}
      aria-disabled={disabled}
      disabled={disabled}
      onClick={disabled ? undefined : onClick}
      className={cn(
        // base card styles
        'relative rounded-md border select-none transition-all duration-150 flex flex-col justify-between p-1',
        SIZE_CLASSES[size],
        // background
        faceDown
          ? 'bg-[var(--color-card-back)] border-[var(--color-card-back)]'
          : 'bg-[var(--color-card-face)] border-[var(--color-card-border)]',
        // selected state
        selected && 'ring-2 ring-[var(--color-neon-lime)] -translate-y-3 shadow-lg shadow-[var(--color-neon-lime)]/20',
        // disabled state
        disabled && 'opacity-40 cursor-not-allowed',
        // clickable state
        !disabled && onClick && 'cursor-pointer hover:shadow-md hover:-translate-y-1 active:translate-y-0',
        className,
      )}
    >
      {faceDown ? (
        <FaceDownPattern />
      ) : (
        <>
          {/* Top-left corner */}
          <div className={cn('flex flex-col items-start', CORNER_SIZE_CLASSES[size])}>
            <span className={cn('font-bold', red ? 'text-[var(--color-suit-red,#dc2626)]' : 'text-[var(--color-suit-black,#111827)]')}>
              {rank}
            </span>
            <span className={cn(red ? 'text-[var(--color-suit-red,#dc2626)]' : 'text-[var(--color-suit-black,#111827)]')}>
              {symbol}
            </span>
          </div>

          {/* Center symbol */}
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
            <span
              className={cn(
                'select-none',
                size === 'sm' ? 'text-base' : size === 'md' ? 'text-xl' : 'text-2xl',
                red ? 'text-[var(--color-suit-red,#dc2626)]' : 'text-[var(--color-suit-black,#111827)]',
              )}
              aria-hidden="true"
            >
              {symbol}
            </span>
          </div>

          {/* Bottom-right corner (rotated) */}
          <div className={cn('flex flex-col items-end rotate-180', CORNER_SIZE_CLASSES[size])}>
            <span className={cn('font-bold', red ? 'text-[var(--color-suit-red,#dc2626)]' : 'text-[var(--color-suit-black,#111827)]')}>
              {rank}
            </span>
            <span className={cn(red ? 'text-[var(--color-suit-red,#dc2626)]' : 'text-[var(--color-suit-black,#111827)]')}>
              {symbol}
            </span>
          </div>
        </>
      )}
    </button>
  );
}

function FaceDownPattern() {
  return (
    <div
      aria-hidden="true"
      className="absolute inset-1 rounded bg-[repeating-linear-gradient(45deg,rgba(255,255,255,0.08)_0px,rgba(255,255,255,0.08)_2px,transparent_2px,transparent_8px)]"
    />
  );
}
