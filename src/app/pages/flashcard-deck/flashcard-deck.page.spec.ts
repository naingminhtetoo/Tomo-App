import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FlashcardDeckPage } from './flashcard-deck.page';

describe('FlashcardDeckPage', () => {
  let component: FlashcardDeckPage;
  let fixture: ComponentFixture<FlashcardDeckPage>;

  beforeEach(() => {
    fixture = TestBed.createComponent(FlashcardDeckPage);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
