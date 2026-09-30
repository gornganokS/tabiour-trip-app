import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBillDto } from './dto/create-bill.dto';
import { UpdateBillDto } from './dto/update-bill.dto';

const personSelect = {
  id: true,
  name: true,
  email: true,
} as const;

const billInclude = {
  payer: {
    select: personSelect,
  },
  splits: {
    include: {
      user: {
        select: personSelect,
      },
    },
  },
} as const;

function makeSplits(
  amount: number,
  userIds: string[],
) {
  if (userIds.length === 0) return [];

  const totalSatang = Math.round(amount * 100);
  const each = Math.floor(totalSatang / userIds.length);
  const remainder = totalSatang % userIds.length;

  return userIds.map((userId, index) => ({
    userId,
    amount: (each + (index < remainder ? 1 : 0)) / 100,
  }));
}

@Injectable()
export class BillsService {
  constructor(private readonly prisma: PrismaService) {}

  private async validateParticipants(
    tripId: string,
    payerId: string,
    splitUserIds: string[],
  ) {
    const trip = await this.prisma.trip.findUnique({
      where: {
        id: tripId,
      },
      include: {
        members: {
          select: {
            userId: true,
          },
        },
      },
    });

    if (!trip) {
      throw new NotFoundException('trip not found');
    }

    const memberIds = new Set([
      trip.ownerId,
      ...trip.members.map((member) => member.userId),
    ]);

    if (
      !memberIds.has(payerId) ||
      splitUserIds.some((id) => !memberIds.has(id))
    ) {
      throw new BadRequestException(
        'The payer and all split participants must be members of the trip.',
      );
    }
  }

  async create(
    tripId: string,
    dto: CreateBillDto,
  ) {
    const splitUserIds = dto.splitUserIds ?? [];

    await this.validateParticipants(
      tripId,
      dto.payerId,
      splitUserIds,
    );

    return this.prisma.bill.create({
      data: {
        tripId,
        title: dto.title.trim(),
        amount: dto.amount,
        payerId: dto.payerId,
        splits: {
          create: makeSplits(
            dto.amount,
            splitUserIds,
          ),
        },
      },
      include: billInclude,
    });
  }

  findAllByTrip(tripId: string) {
    return this.prisma.bill.findMany({
      where: {
        tripId,
      },
      include: billInclude,
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  async findOne(
    tripId: string,
    id: string,
  ) {
    const bill = await this.prisma.bill.findFirst({
      where: {
        id,
        tripId,
      },
      include: billInclude,
    });

    if (!bill) {
      throw new NotFoundException('bill not found');
    }

    return bill;
  }

  async update(
    tripId: string,
    id: string,
    dto: UpdateBillDto,
  ) {
    const bill = await this.findOne(tripId, id);

    const payerId = dto.payerId ?? bill.payerId;

    const recalculate =
      dto.amount !== undefined ||
      dto.splitUserIds !== undefined;

    const splitUserIds = dto.splitUserIds ??
      [...new Set(bill.splits.map((split) => split.userId))];

    // แก้ยอดหรือรายชื่อผู้หาร จึงต้องตรวจสมาชิกอีกครั้ง
    if (recalculate) {
      await this.validateParticipants(
        tripId,
        payerId,
        splitUserIds,
      );
    } else if (dto.payerId !== undefined) {
      await this.validateParticipants(
        tripId,
        payerId,
        [],
      );
    }

    const amount = dto.amount ?? bill.amount;

    return this.prisma.bill.update({
      where: {
        id,
        tripId,
      },
      data: {
        title: dto.title?.trim(),
        payerId,
        amount,
        ...(recalculate
          ? {
              splits: {
                deleteMany: {},
                create: makeSplits(amount, splitUserIds),
              },
            }
          : {}),
      },
      include: billInclude,
    });
  }

  async remove(
    tripId: string,
    id: string,
    requesterId: string,
  ) {
    const trip = await this.prisma.trip.findUnique({
      where: {
        id: tripId,
      },
      select: {
        ownerId: true,
      },
    });

    if (!trip) {
      throw new NotFoundException('trip not found');
    }

    if (trip.ownerId !== requesterId) {
      throw new ForbiddenException(
        'only owner can delete bills',
      );
    }

    const result = await this.prisma.bill.deleteMany({
      where: {
        id,
        tripId,
      },
    });

    if (!result.count) {
      throw new NotFoundException('bill not found');
    }

    return { deleted: true };
  }
}