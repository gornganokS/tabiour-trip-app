import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
} from '@nestjs/common';
import { BillSplitsService } from './bill-splits.service';
import { CreateBillSplitDto } from './dto/create-bill-split.dto';
import { UpdateBillSplitDto } from './dto/update-bill-split.dto';

@Controller('bills/:billId/splits')
export class BillSplitsController {
  constructor(private readonly billSplitsService: BillSplitsService) {}

  @Post()
  create(@Param('billId') billId: string, @Body() dto: CreateBillSplitDto) {
    return this.billSplitsService.create(billId, dto);
  }

  @Get()
  findAll(@Param('billId') billId: string) {
    return this.billSplitsService.findAll(billId);
  }

  @Get(':id')
  findOne(@Param('billId') billId: string, @Param('id') id: string) {
    return this.billSplitsService.findOne(billId, id);
  }

  @Patch(':id')
  update(
    @Param('billId') billId: string,
    @Param('id') id: string,
    @Body() dto: UpdateBillSplitDto,
  ) {
    return this.billSplitsService.update(billId, id, dto);
  }

  @Delete(':id')
  remove(@Param('billId') billId: string, @Param('id') id: string) {
    return this.billSplitsService.remove(billId, id);
  }
}
