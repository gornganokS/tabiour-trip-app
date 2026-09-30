import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'node:path';

import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(
    AppModule,
  );

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );

  app.useStaticAssets(
    join(process.cwd(), 'uploads', 'avatars'),
    {
      prefix: '/uploads/avatars/',
      index: false,
      dotfiles: 'deny',
    },
  );

  await app.listen(
    process.env.PORT ?? 3000,
    '0.0.0.0',
  );
}

void bootstrap();