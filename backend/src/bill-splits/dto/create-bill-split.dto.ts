import { IsNumber, IsUUID } from 'class-validator';

export class CreateBillSplitDto {
  @IsUUID()
  userId!: string;

  @IsNumber()
  amount!: number;
}
