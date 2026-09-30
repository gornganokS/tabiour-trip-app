import { Test, TestingModule } from '@nestjs/testing';
import { TripMembersService } from './trip-members.service';

describe('TripMembersService', () => {
  let service: TripMembersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [TripMembersService],
    }).compile();

    service = module.get<TripMembersService>(TripMembersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
