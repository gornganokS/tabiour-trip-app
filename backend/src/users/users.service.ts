import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { BadRequestException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { mkdir, unlink, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import sharp from 'sharp';

const profileSelect = {
  id: true,
  name: true,
  email: true,
  phone: true,
  avatarUrl: true,
};

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  findAll() {
    return this.prisma.user.findMany({
      select: {
        id: true,
        name: true,
        email: true,
      },
    });
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: {
        id: userId,
      },
      select: profileSelect,
    });

    if (!user) {
      throw new NotFoundException('user not found');
    }

    return user;
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
  ) {
    try {
      return await this.prisma.user.update({
        where: {
          id: userId,
        },
        data: {
          name: dto.name.trim(),
          email: dto.email.trim(),
          phone: dto.phone.trim() || null,
        },
        select: profileSelect,
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError) {
        if (error.code === 'P2002') {
          throw new ConflictException(
            'email already exist',
          );
        }

        if (error.code === 'P2025') {
          throw new NotFoundException(
            'user not found',
          );
        }
      }

      throw error;
    }
  }

  async uploadAvatar(
  userId: string,
  file?: Express.Multer.File,
) {
  if (!file?.buffer?.length) {
    throw new BadRequestException(
      'Please select an image.',
    );
  }

  if (file.buffer.length > 5 * 1024 * 1024) {
    throw new BadRequestException(
      'The image must be smaller than 5 MB.',
    );
  }

  const currentUser = await this.getProfile(userId);

  let image: Buffer;

  try {
    // ตรวจและถอดรหัสรูปจริง ไม่เชื่อเพียงนามสกุลไฟล์
    const processor = sharp(file.buffer, {
      limitInputPixels: 20_000_000,
    });

    const metadata = await processor.metadata();

    if (
      !metadata.format ||
      !['jpeg', 'png', 'webp', 'heif'].includes(metadata.format)
    ) {
      throw new Error('Unsupported image format');
    }

    image = await processor
      .rotate()
      .resize(512, 512, {
        fit: 'cover',
        position: 'centre',
      })
      .flatten({
        background: '#ffffff',
      })
      .jpeg({
        quality: 85,
      })
      .toBuffer();
  } catch {
    throw new BadRequestException(
      'Unable to read this image. Please select a JPG, PNG, or WebP image.',
    );
  }

  const directory = join(
    process.cwd(),
    'uploads',
    'avatars',
  );

  await mkdir(directory, {
    recursive: true,
  });

  const filename = `${randomUUID()}.jpg`;
  const filePath = join(directory, filename);
  const avatarUrl = `/uploads/avatars/${filename}`;

  await writeFile(filePath, image);

  let updatedUser;

  try {
    updatedUser = await this.prisma.user.update({
      where: {
        id: userId,
      },
      data: {
        avatarUrl,
      },
      select: profileSelect,
    });
  } catch (error) {
    // ถ้าบันทึกฐานข้อมูลไม่สำเร็จ ให้ลบไฟล์ใหม่ออก
    await unlink(filePath).catch(() => undefined);
    throw error;
  }

  // ลบรูปเก่าหลังบันทึกรูปใหม่สำเร็จ
  const oldFilename = currentUser.avatarUrl?.match(
    /^\/uploads\/avatars\/([a-f0-9-]+\.jpg)$/,
  )?.[1];

  if (oldFilename) {
    await unlink(
      join(directory, oldFilename),
    ).catch(() => undefined);
  }
  return updatedUser;
}
}