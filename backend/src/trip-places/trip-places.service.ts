import { Injectable } from '@nestjs/common';
import { CreatePlaceDto } from './dto/create-place.dto';
import { UpdatePlaceDto } from './dto/update-place.dto';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class TripPlacesService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreatePlaceDto) {
    return this.prisma.place.create({
      data: dto,
    });
  }

  async findAllByTrip(tripId: string) {
    return this.prisma.place.findMany({
      where: { tripId },
      orderBy: { id: 'asc' },
    });
  }

  async findOne(id: string) {
    return this.prisma.place.findUnique({
      where: { id },
    });
  }

  async update(id: string, dto: UpdatePlaceDto) {
    return this.prisma.place.update({
      where: { id },
      data: dto,
    });
  }

  async remove(tripId: string, placeId: string) {
    return this.prisma.place.delete({
      where: {
        id: placeId,
      },
    });
  }
}
