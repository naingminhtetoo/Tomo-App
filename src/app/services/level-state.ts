import { Injectable, signal } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class LevelStateService {
  // A signal to hold the currently selected level (e.g., 'n2')
  selectedLevel = signal<string | null>(null);

  /**
   * Sets the current level. This will be called from the level-select page.
   * @param level The level identifier (e.g., 'n2', 'n3').
   */
  setLevel(level: string) {
    this.selectedLevel.set(level);
  }
}
