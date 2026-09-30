import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';

import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

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

  @Post('profile/avatar')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: {
        fileSize: 5 * 1024 * 1024,
        files: 1,
      },
    }),
  )
  uploadAvatar(
    @Req() req: AuthRequest,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.usersService.uploadAvatar(
      req.user.userId,
      file,
    );
  }
}