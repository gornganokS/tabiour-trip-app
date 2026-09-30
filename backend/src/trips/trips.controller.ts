import {
  Body,
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Request,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { TripsService } from './trips.service';
import { CreateTripDto } from './dto/create-trip.dto';
import { Request as ExpressRequest } from 'express';
import { UpdateTripDto } from './dto/update-trip.dto';

interface AuthRequest extends ExpressRequest {
  user: {
    userId: string;
  };
}

@Controller('trips')
export class TripsController {
  constructor(private readonly tripsService: TripsService) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Body() dto: CreateTripDto, @Request() req: AuthRequest) {
    return this.tripsService.create(dto, req.user.userId);
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  findAll(@Request() req: AuthRequest) {
    return this.tripsService.findAll(req.user.userId);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  findOne(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.tripsService.findOne(id, req.user.userId);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  update(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: UpdateTripDto,
  ) {
    return this.tripsService.update(id, req.user.userId, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  remove(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.tripsService.remove(id, req.user.userId);
  }
}
