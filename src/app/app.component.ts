import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { Platform } from '@ionic/angular';
import { App } from '@capacitor/app';
import { ThemeService } from './services/theme';

@Component({
  selector: 'app-root',
  templateUrl: 'app.component.html',
  styleUrls: ['app.component.scss'],
  standalone: false,
})
export class AppComponent {
  constructor(
    private platform: Platform,
    private router: Router,
    private themeService: ThemeService
  ) {
    this.initializeApp();
  }

  initializeApp() {
    this.platform.ready().then(() => {
      this.themeService.loadSavedTheme(); // 3. Load the theme on startup

      this.platform.backButton.subscribeWithPriority(-1, () => {
        // Now, check if the current URL is the new level-select page
        if (this.router.url === '/level-select' || this.router.url === '/') {
          App.exitApp();
        }
      });
    });
  }
}

