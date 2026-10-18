/**
 * Thin banner shown at the top of the game board when the local socket is
 * disconnected.  Disappears automatically once the socket reconnects.
 */
import React from 'react';
import { useGameStore } from '@/store/gameStore';

export function ConnectionBanner(): React.ReactElement | null {
  const isDisconnected = useGameStore((s) => s.isDisconnected);

  if (!isDisconnected) return null;

  return (
    <div className="fixed inset-x-0 top-0 z-50 flex items-center justify-center bg-[var(--color-danger-red)] px-4 py-2 text-sm font-medium text-white shadow-md">
      Connection lost — reconnecting…
    </div>
  );
}
