import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IonicModule } from '@ionic/angular';
import { Router } from '@angular/router';
import { LevelStateService } from 'src/app/services/level-state';
import { ThemeService } from 'src/app/services/theme';

@Component({
  selector: 'app-level-select',
  templateUrl: './level-select.page.html',
  styleUrls: ['./level-select.page.scss'],
  standalone: true,
  imports: [CommonModule, IonicModule],
})
export class LevelSelectPage {
  private router = inject(Router);
  private levelStateService = inject(LevelStateService);
  public themeService = inject(ThemeService); // Make public for the template

  selectLevel(level: string) {
    this.levelStateService.setLevel(level);
    this.router.navigate(['/home']);
  }

  /**
   * Toggles the theme when the switch is clicked.
   */
  toggleTheme() {
    this.themeService.toggleTheme();
  }
}

