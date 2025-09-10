import { TestBed } from '@angular/core/testing';

import { Vocabulary } from './vocabulary';

describe('Vocabulary', () => {
  let service: Vocabulary;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(Vocabulary);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
