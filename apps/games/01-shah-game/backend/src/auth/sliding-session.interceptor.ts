import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { type Request } from 'express';
import { type Observable, tap } from 'rxjs';
import { AuthService } from './auth.service';

/**
 * Extends the Redis session TTL to 24h on every authenticated request
 * (sliding window). Only fires when a sessionToken is present.
 */
@Injectable()
export class SlidingSessionInterceptor implements NestInterceptor {
  constructor(private readonly authService: AuthService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<Request>();

    return next.handle().pipe(
      tap(() => {
        const token = request.sessionToken;
        if (token) {
          // Fire-and-forget — do not block the response
          void this.authService.refreshSession(token);
        }
      }),
    );
  }
}
