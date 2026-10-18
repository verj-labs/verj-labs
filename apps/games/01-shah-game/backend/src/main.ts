import { ValidationPipe } from '@nestjs/common';
import { NestFactory, Reflector } from '@nestjs/core';
import { AppModule } from './app.module';
import { SessionGuard } from './auth/auth.guard';
import { AuthService } from './auth/auth.service';
import { SlidingSessionInterceptor } from './auth/sliding-session.interceptor';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);

  app.enableCors({
    origin: (process.env.FRONTEND_URL ?? 'http://localhost:5173').replace(/\/$/, ''),
    credentials: true,
  });

  // Global validation pipe — strips unknown fields, whitelist only
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  // Global session guard — @Public() endpoints bypass it
  const reflector = app.get(Reflector);
  const authService = app.get(AuthService);
  app.useGlobalGuards(new SessionGuard(authService, reflector));

  // Global sliding TTL interceptor
  app.useGlobalInterceptors(new SlidingSessionInterceptor(authService));

  await app.listen(process.env.PORT ?? 3000);
}

void bootstrap();
