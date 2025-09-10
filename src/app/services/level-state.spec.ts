import { TestBed } from '@angular/core/testing';

import { LevelState } from './level-state';

describe('LevelState', () => {
  let service: LevelState;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(LevelState);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
