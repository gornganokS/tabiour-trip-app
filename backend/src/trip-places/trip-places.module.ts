// src/places/places.module.ts
import { Module } from '@nestjs/common';
import { TripPlacesService } from './trip-places.service';
import { TripPlacesController } from './trip-places.controller';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  controllers: [TripPlacesController],
  providers: [TripPlacesService, PrismaService],
})
export class TripPlacesModule {}
