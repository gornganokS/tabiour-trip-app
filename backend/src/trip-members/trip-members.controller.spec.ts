import { Test, TestingModule } from '@nestjs/testing';
import { TripMembersController } from './trip-members.controller';

describe('TripMembersController', () => {
  let controller: TripMembersController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [TripMembersController],
    }).compile();

    controller = module.get<TripMembersController>(TripMembersController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
