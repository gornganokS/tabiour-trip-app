import { Test, TestingModule } from '@nestjs/testing';
import { BillSplitsService } from './bill-splits.service';

describe('BillSplitsService', () => {
  let service: BillSplitsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [BillSplitsService],
    }).compile();

    service = module.get<BillSplitsService>(BillSplitsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
