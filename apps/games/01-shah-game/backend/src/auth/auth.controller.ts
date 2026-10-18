import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Req,
} from '@nestjs/common';
import { type Request } from 'express';
import { AuthService } from './auth.service';
import { CreateSessionDto } from './dto/create-session.dto';
import { Public } from './public.decorator';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('session')
  @HttpCode(HttpStatus.CREATED)
  async createSession(
    @Body() dto: CreateSessionDto,
  ): ReturnType<AuthService['createSession']> {
    return this.authService.createSession(dto.displayName);
  }

  @Get('me')
  getMe(@Req() req: Request): {
    player: { id: string; displayName: string };
    matchId: string | null;
  } {
    const { playerId, displayName, matchId } = req.user!;
    return { player: { id: playerId, displayName }, matchId };
  }

  @Delete('session')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteSession(@Req() req: Request): Promise<void> {
    await this.authService.deleteSession(req.sessionToken!);
  }
}
