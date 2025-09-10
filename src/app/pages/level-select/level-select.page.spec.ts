import { ComponentFixture, TestBed } from '@angular/core/testing';
import { LevelSelectPage } from './level-select.page';

describe('LevelSelectPage', () => {
  let component: LevelSelectPage;
  let fixture: ComponentFixture<LevelSelectPage>;

  beforeEach(() => {
    fixture = TestBed.createComponent(LevelSelectPage);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
