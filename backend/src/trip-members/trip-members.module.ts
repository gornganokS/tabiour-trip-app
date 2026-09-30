import { Module } from '@nestjs/common';
import { TripMembersService } from './trip-members.service';
import { TripMembersController } from './trip-members.controller';

@Module({
  providers: [TripMembersService],
  controllers: [TripMembersController],
})
export class TripMembersModule {}
