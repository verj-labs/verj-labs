import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsIn,
  IsString,
  ValidateNested,
} from 'class-validator';

const VALID_SUITS = ['hearts', 'diamonds', 'clubs', 'spades'] as const;
const VALID_RANKS = [
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '10',
  'J',
  'Q',
  'K',
  'A',
  '2',
] as const;

export class CardDto {
  @IsString()
  @IsIn(VALID_RANKS)
  rank!: string;

  @IsString()
  @IsIn(VALID_SUITS)
  suit!: string;
}

export class PlayIntentDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(4)
  @ValidateNested({ each: true })
  @Type(() => CardDto)
  cards!: CardDto[];
}
