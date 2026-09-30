import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Patch,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { TripPlacesService } from './trip-places.service';
import { CreatePlaceDto } from './dto/create-place.dto';
import { UpdatePlaceDto } from './dto/update-place.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('trips/:tripId/places')
export class TripPlacesController {
  constructor(private readonly placesService: TripPlacesService) {}

  @Post()
  create(@Body() dto: CreatePlaceDto) {
    return this.placesService.create(dto);
  }

  @Get()
  findAllByTrip(@Param('tripId') tripId: string) {
    return this.placesService.findAllByTrip(tripId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.placesService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdatePlaceDto) {
    return this.placesService.update(id, dto);
  }

  @Delete(':placeId')
  remove(@Param('tripId') tripId: string, @Param('placeId') placeId: string) {
    return this.placesService.remove(tripId, placeId);
  }
}
