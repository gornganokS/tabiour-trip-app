import { Module } from '@nestjs/common';
import { BillSplitsService } from './bill-splits.service';
import { BillSplitsController } from './bill-splits.controller';

@Module({
  controllers: [BillSplitsController],
  providers: [BillSplitsService],
})
export class BillSplitsModule {}
