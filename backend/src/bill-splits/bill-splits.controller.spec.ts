import { Test, TestingModule } from '@nestjs/testing';
import { BillSplitsController } from './bill-splits.controller';

describe('BillSplitsController', () => {
  let controller: BillSplitsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [BillSplitsController],
    }).compile();

    controller = module.get<BillSplitsController>(BillSplitsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
