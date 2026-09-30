import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { TripAccessGuard } from '../trips/trip-access.guard';
import { TripMembersService } from './trip-members.service';
import { AddMemberDto } from './dto/add-member.dto';

interface AuthRequest {
  user: {
    userId: string;
  };
}

@Controller('trips/:tripId/members')
@UseGuards(JwtAuthGuard, TripAccessGuard)
export class TripMembersController {
  constructor(
    private readonly service: TripMembersService,
  ) {}

  @Post()
  addMember(
    @Param('tripId') tripId: string,
    @Body() dto: AddMemberDto,
    @Req() req: AuthRequest,
  ) {
    return this.service.addMember(
      tripId,
      dto.email,
      req.user.userId,
    );
  }

  @Get()
  getMembers(@Param('tripId') tripId: string) {
    return this.service.getMembers(tripId);
  }

  @Delete(':userId')
  removeMember(
    @Param('tripId') tripId: string,
    @Param('userId') userId: string,
    @Req() req: AuthRequest,
  ) {
    return this.service.removeMember(
      tripId,
      userId,
      req.user.userId,
    );
  }
}