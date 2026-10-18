import { cn } from '@/lib/utils';

interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg';
  /** Defaults to neon-lime; pass a Tailwind color class to override (e.g. 'text-white') */
  color?: string;
  className?: string;
}

const SIZE_CLASSES = {
  sm: 'h-4 w-4 border-2',
  md: 'h-8 w-8 border-2',
  lg: 'h-12 w-12 border-4',
} as const;

export function LoadingSpinner({ size = 'md', color, className }: LoadingSpinnerProps) {
  return (
    <span
      role="status"
      aria-label="Loading"
      className={cn(
        'inline-block rounded-full border-b-transparent animate-spin',
        SIZE_CLASSES[size],
        color ?? 'border-[var(--color-neon-lime)]',
        className,
      )}
    />
  );
}

