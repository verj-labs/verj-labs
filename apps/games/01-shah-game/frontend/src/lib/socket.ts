import { io, type Socket } from 'socket.io-client';
import { config } from '@/lib/config';
import { STORAGE_KEY_TOKEN } from '@/lib/constants';

let socket: Socket | null = null;

/**
 * Returns the singleton Socket.IO client, creating it (and connecting) on
 * first call or after a `disconnectSocket()` call.
 *
 * The bearer token is sent via the Socket.IO auth handshake so the gateway
 * can authenticate this connection without a separate HTTP round-trip.
 *
 * IMPORTANT: We only create a new socket when none exists (`!socket`).
 * Checking `!socket.connected` would orphan reconnecting sockets.
 */
export function getSocket(token?: string): Socket {
  if (!socket) {
    const authToken =
      token || localStorage.getItem(STORAGE_KEY_TOKEN) || '';
    console.log('[socket] Creating new Socket.IO connection');
    socket = io(config.socketUrl, {
      auth: { token: authToken },
      autoConnect: true,
      transports: ['websocket'],
    });
    socket.on('connect', () => {
      console.log(`[socket] Connected — id: ${socket?.id}`);
    });
    socket.on('disconnect', (reason) => {
      console.log(`[socket] Disconnected — reason: ${reason}`);
    });
    socket.on('connect_error', (err) => {
      console.error(`[socket] Connection error: ${err.message}`);
    });
  }
  return socket;
}

/**
 * Disconnect and clear the singleton.  Call when the player leaves a match
 * so stale event listeners don't accumulate.
 */
export function disconnectSocket(): void {
  if (socket) {
    console.log('[socket] Disconnecting and clearing singleton');
    socket.disconnect();
    socket = null;
  }
}
