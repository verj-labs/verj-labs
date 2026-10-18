import { IsString, Length, Matches } from 'class-validator';

/** Valid characters for room codes: A-Z minus O,I plus 2-9 */
const ROOM_CODE_PATTERN = /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{4}$/;

export class JoinMatchDto {
  @IsString()
  @Length(4, 4, { message: 'Room code must be exactly 4 characters.' })
  @Matches(ROOM_CODE_PATTERN, {
    message: 'Room code contains invalid characters.',
  })
  roomCode!: string;
}
