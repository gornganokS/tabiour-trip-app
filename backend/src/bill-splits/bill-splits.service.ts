import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateBillSplitDto } from './dto/create-bill-split.dto';
import { UpdateBillSplitDto } from './dto/update-bill-split.dto';

@Injectable()
export class BillSplitsService {
  constructor(private prisma: PrismaService) {}

  async create(billId: string, dto: CreateBillSplitDto) {
    return this.prisma.billSplit.create({
      data: {
        ...dto,
        billId,
      },
    });
  }

  async findAll(billId: string) {
    return this.prisma.billSplit.findMany({
      where: {
        billId,
      },
    });
  }

  async findOne(billId: string, id: string) {
    return this.prisma.billSplit.findFirst({
      where: {
        id,
        billId,
      },
    });
  }

  async update(billId: string, id: string, dto: UpdateBillSplitDto) {
  return this.prisma.billSplit.update({
    where: {
      id,
      billId,
    },
    data: {
      ...dto,
      billId,
    },
  });
}

async remove(billId: string, id: string) {
  return this.prisma.billSplit.delete({
    where: {
      id,
      billId,
    },
  });
}
}
