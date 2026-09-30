import {
  ArrayNotEmpty,
  ArrayUnique,
  IsArray,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateBillDto {
  @IsUUID()
  payerId!: string;

  @IsString()
  @Matches(/\S/, {
    message: 'please fill expense name',
  })
  @MaxLength(200)
  title!: string;

  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  @Max(100000000)
  amount!: number;

  @IsOptional()
  @IsArray()
  @ArrayNotEmpty()
  @ArrayUnique()
  @IsUUID('all', { each: true })
  splitUserIds?: string[];
}