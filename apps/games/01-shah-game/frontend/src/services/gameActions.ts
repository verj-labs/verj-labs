/**
 * Outgoing game actions over the WebSocket.
 *
 * Each function emits one client→server event and returns a promise that
 * resolves when we receive the corresponding server→client acknowledgement
 * (or rejects after `TIMEOUT_MS`).
 */
import { getSocket } from '@/lib/socket';
import { type Card } from '@/types/card';

const TIMEOUT_MS = 10_000;

function withTimeout<T>(promise: Promise<T>): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) =>
      setTimeout(() => reject(new Error('Action timed out.')), TIMEOUT_MS),
    ),
  ]);
}

/**
 * Send a play intent (one or more cards).
 *
 * The server replies with `game:state_updated` (broadcast to room) or
 * `game:play_rejected` (only to this socket).  We capture the rejection here
 * so the caller gets a clean error string.
 */
export function sendPlay(cards: Card[]): Promise<void> {
  return withTimeout(
    new Promise<void>((resolve, reject) => {
      const socket = getSocket();
      if (!socket.connected) {
        reject(new Error('Not connected.'));
        return;
      }

      // optimistically resolve on the next state update — rejection overrides it
      let settled = false;

      const onRejected = ({ reason }: { reason: string }) => {
        if (settled) return;
        settled = true;
        socket.off('game:play_rejected', onRejected);
        socket.off('game:state_updated', onUpdated);
        reject(new Error(reason));
      };

      const onUpdated = () => {
        if (settled) return;
        settled = true;
        socket.off('game:play_rejected', onRejected);
        socket.off('game:state_updated', onUpdated);
        resolve();
      };

      socket.once('game:play_rejected', onRejected);
      socket.once('game:state_updated', onUpdated);

      socket.emit('game:play', { cards });
    }),
  );
}

/**
 * Send a pass intent.
 */
export function sendPass(): Promise<void> {
  return withTimeout(
    new Promise<void>((resolve, reject) => {
      const socket = getSocket();
      if (!socket.connected) {
        reject(new Error('Not connected.'));
        return;
      }

      let settled = false;

      const onRejected = ({ reason }: { reason: string }) => {
        if (settled) return;
        settled = true;
        socket.off('game:play_rejected', onRejected);
        socket.off('game:state_updated', onUpdated);
        reject(new Error(reason));
      };

      const onUpdated = () => {
        if (settled) return;
        settled = true;
        socket.off('game:play_rejected', onRejected);
        socket.off('game:state_updated', onUpdated);
        resolve();
      };

      socket.once('game:play_rejected', onRejected);
      socket.once('game:state_updated', onUpdated);

      socket.emit('game:pass');
    }),
  );
}
