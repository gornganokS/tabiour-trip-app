import { Injectable, NotFoundException } from '@nestjs/common';
import { Trip } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTripDto } from './dto/create-trip.dto';
import { UpdateTripDto } from './dto/update-trip.dto';

@Injectable()
export class TripsService {
  constructor(private readonly prisma: PrismaService) {}

  private async validateOwner(id: string, ownerId: string): Promise<Trip> {
    const trip = await this.prisma.trip.findFirst({
      where: {
        id,
        ownerId,
      },
    });
    if (!trip) {
      throw new NotFoundException('Trip not found');
    }
    return trip;
  }

  create(dto: CreateTripDto, ownerId: string): Promise<Trip> {
    return this.prisma.trip.create({
      data: {
        name: dto.name,
        description: dto.description,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
        ownerId,
      },
    });
  }

findAll(userId: string): Promise<Trip[]> {
  return this.prisma.trip.findMany({
    where: {
      OR: [
        {
          ownerId: userId,
        },
        {
          members: {
            some: {
              userId,
            },
          },
        },
      ],
    },
    orderBy: {
      createdAt: 'desc',
    },
  });
}

async findOne(id: string, userId: string) {
  const personSelect = {
    id: true,
    name: true,
    email: true,
    avatarUrl: true,
  } as const;

  const trip = await this.prisma.trip.findFirst({
    where: {
      id,
      OR: [
        {
          ownerId: userId,
        },
        {
          members: {
            some: {
              userId,
            },
          },
        },
      ],
    },
    include: {
      owner: {
        select: personSelect,
      },
      members: {
        include: {
          user: {
            select: personSelect,
          },
        },
      },
      places: true,
      bills: {
        include: {
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
        },
        orderBy: {
          createdAt: 'desc',
        },
      },
    },
  });

  if (!trip) {
    throw new NotFoundException(
      'Trip not found or access denied.',
    );
  }

  const allPeople = [
    trip.owner,
    ...trip.members.map((member) => member.user),
  ];

  const people = allPeople.filter(
    (person, index) =>
      allPeople.findIndex((item) => item.id === person.id) === index,
  );

  return {
    ...trip,
    people,
    currentUserId: userId,
  };
}
  async update(id: string, ownerId: string, dto: UpdateTripDto): Promise<Trip> {
    await this.validateOwner(id, ownerId);

    return this.prisma.trip.update({
      where: { id },
      data: dto,
    });
  }
  async remove(id: string, ownerId: string): Promise<void> {
    await this.validateOwner(id, ownerId);

    await this.prisma.trip.delete({
      where: {
        id,
      },
    });
  }
}
