import { Test, TestingModule } from '@nestjs/testing';
import { TripPlacesService } from './trip-places.service';

describe('TripPlacesService', () => {
  let service: TripPlacesService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [TripPlacesService],
    }).compile();

    service = module.get<TripPlacesService>(TripPlacesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
