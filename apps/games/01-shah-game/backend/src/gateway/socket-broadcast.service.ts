import { Injectable } from '@nestjs/common';
import { type Server } from 'socket.io';

/**
 * Bridges the Socket.IO server reference from the gateway to other services.
 *
 * The gateway sets `this.server` in `afterInit()`.  Any service that needs to
 * broadcast to sockets injects this service instead of depending on the gateway
 * directly (which would create a circular dependency).
 */
@Injectable()
export class SocketBroadcastService {
  private _server: Server | null = null;

  set server(s: Server) {
    this._server = s;
  }

  get server(): Server | null {
    return this._server;
  }

  /** Emit an event to everyone in a Socket.IO room */
  toRoom(room: string, event: string, data: unknown): void {
    this._server?.to(room).emit(event, data);
  }

  /** Emit an event to a single socket by its id */
  toSocket(socketId: string, event: string, data: unknown): void {
    this._server?.to(socketId).emit(event, data);
  }

  /** Retrieve all sockets currently in a room */
  // eslint-disable-next-line @typescript-eslint/explicit-function-return-type
  async socketsInRoom(room: string) {
    if (!this._server) return [];
    return this._server.in(room).fetchSockets();
  }
}
