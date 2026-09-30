import {
  IsEmail,
  IsString,
  IsNotEmpty,
  MinLength,
} from 'class-validator';

export class RegisterDto {
  @IsEmail()
  email!: string;

  @MinLength(6)
  password!: string;

  @IsString()
  @IsNotEmpty()
  name!: string;
}