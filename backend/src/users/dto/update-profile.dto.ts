import {
  IsEmail,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

export class UpdateProfileDto {
  @IsString()
  @Matches(/\S/, {
    message: 'please fill your name',
  })
  @MaxLength(100)
  name!: string;

  @IsEmail({}, {
    message: 'invalid format',
  })
  email!: string;

  @IsString()
  @MaxLength(30)
  phone!: string;
}