import {
  CanActivate,
  ExecutionContext,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class TripAccessGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<{
      params: {
        tripId: string;
      };
      user: {
        userId: string;
      };
    }>();

    const trip = await this.prisma.trip.findFirst({
      where: {
        id: req.params.tripId,
        OR: [
          {
            ownerId: req.user.userId,
          },
          {
            members: {
              some: {
                userId: req.user.userId,
              },
            },
          },
        ],
      },
      select: {
        id: true,
      },
    });

    if (!trip) {
      throw new NotFoundException(
        'trip not found or unauthorized',
      );
    }

    return true;
  }
}