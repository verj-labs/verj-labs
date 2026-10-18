import { Transform } from 'class-transformer';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class CreateSessionDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(2, { message: 'Display name must be at least 2 characters.' })
  @MaxLength(32, { message: 'Display name must be at most 32 characters.' })
  displayName!: string;
}
