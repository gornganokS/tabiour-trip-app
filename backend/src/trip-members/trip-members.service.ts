import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class TripMembersService {
  constructor(private readonly prisma: PrismaService) {}

  private async requireOwner(
    tripId: string,
    requesterId: string,
  ) {
    const trip = await this.prisma.trip.findUnique({
      where: {
        id: tripId,
      },
    });

    if (!trip) {
      throw new NotFoundException('trip not found');
    }

    if (trip.ownerId !== requesterId) {
      throw new ForbiddenException(
        'only trip owner is authorize',
      );
    }

    return trip;
  }

  async addMember(
    tripId: string,
    email: string,
    requesterId: string,
  ) {
    const trip = await this.requireOwner(
      tripId,
      requesterId,
    );

    const user = await this.prisma.user.findUnique({
      where: {
        email: email.trim(),
      },
      select: {
        id: true,
      },
    });

    if (!user) {
      throw new NotFoundException(
        'this email need to register first',
      );
    }

    if (user.id === trip.ownerId) {
      throw new ConflictException(
        'trip owner is already a member to the trip',
      );
    }

    try {
      return await this.prisma.tripMember.create({
        data: {
          tripId,
          userId: user.id,
          role: 'member',
        },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true,
            },
          },
        },
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException(
          'member already exist in this trip',
        );
      }

      throw error;
    }
  }

  getMembers(tripId: string) {
    return this.prisma.tripMember.findMany({
      where: {
        tripId,
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
      orderBy: {
        createdAt: 'asc',
      },
    });
  }

  async removeMember(
    tripId: string,
    userId: string,
    requesterId: string,
  ) {
    await this.requireOwner(tripId, requesterId);

    const result = await this.prisma.tripMember.deleteMany({
      where: {
        tripId,
        userId,
      },
    });

    if (!result.count) {
      throw new NotFoundException('member not found');
    }

    return { deleted: true };
  }
}