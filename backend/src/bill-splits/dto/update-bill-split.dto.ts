import { PartialType } from '@nestjs/mapped-types';
import { CreateBillSplitDto } from './create-bill-split.dto';

export class UpdateBillSplitDto extends PartialType(CreateBillSplitDto) {}
