import { IsEmail } from 'class-validator';

export class AddMemberDto {
  @IsEmail({}, {
    message: 'please enter a valid email',
  })
  email!: string;
}