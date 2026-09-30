import { IsString, IsOptional, IsNumber } from 'class-validator';

export class CreatePlaceDto {
  @IsString()
  tripId!: string;

  @IsString()
  name!: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsNumber()
  lat?: number;

  @IsOptional()
  @IsNumber()
  lng?: number;
}
