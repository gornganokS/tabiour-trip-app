import {
  Body,
  Controller,
  Get,
  Patch,
  Req,
  UseGuards,
} from '@nestjs/common';
import { UsersService } from './users/users.service';
import { JwtAuthGuard } from './auth/jwt-auth.guard';
import { UpdateProfileDto } from './users/dto/update-profile.dto';
interface AuthRequest {
  user: {
    userId: string;
    email: string;
  };
}
@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
constructor(
private readonly usersService: UsersService,
  ) {}
  @Get()
  findAll() {
    return this.usersService.findAll();
  }
  @Get('profile')
  getProfile(@Req() req: AuthRequest) {
    return this.usersService.getProfile(
      req.user.userId,
    );
  }
  @Patch('profile')
  updateProfile(
    @Req() req: AuthRequest,
    @Body() dto: UpdateProfileDto,
  ) {
    return this.usersService.updateProfile(
      req.user.userId,
      dto,
    );
  }
}