import { Test, TestingModule } from '@nestjs/testing';
import { TripPlacesController } from './trip-places.controller';

describe('TripPlacesController', () => {
  let controller: TripPlacesController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [TripPlacesController],
    }).compile();

    controller = module.get<TripPlacesController>(TripPlacesController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
