import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { BillsService } from './bills.service';
import { CreateBillDto } from './dto/create-bill.dto';
import { UpdateBillDto } from './dto/update-bill.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { TripAccessGuard } from '../trips/trip-access.guard';

interface AuthRequest {
  user: {
    userId: string;
  };
}

@Controller('trips/:tripId/bills')
@UseGuards(JwtAuthGuard, TripAccessGuard)
export class BillsController {
  constructor(
    private readonly billsService: BillsService,
  ) {}

  @Post()
  create(
    @Param('tripId') tripId: string,
    @Body() dto: CreateBillDto,
  ) {
    return this.billsService.create(tripId, dto);
  }

  @Get()
  findAll(@Param('tripId') tripId: string) {
    return this.billsService.findAllByTrip(tripId);
  }

  @Get(':id')
  findOne(
    @Param('tripId') tripId: string,
    @Param('id') id: string,
  ) {
    return this.billsService.findOne(tripId, id);
  }

  @Patch(':id')
  update(
    @Param('tripId') tripId: string,
    @Param('id') id: string,
    @Body() dto: UpdateBillDto,
  ) {
    return this.billsService.update(tripId, id, dto);
  }

  @Delete(':id')
  remove(
    @Param('tripId') tripId: string,
    @Param('id') id: string,
    @Req() req: AuthRequest,
  ) {
    return this.billsService.remove(
      tripId,
      id,
      req.user.userId,
    );
  }
}