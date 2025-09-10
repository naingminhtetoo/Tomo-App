import { Injectable, Renderer2, RendererFactory2, signal, effect } from '@angular/core';
import { Preferences } from '@capacitor/preferences';

// Define the possible theme settings
type Theme = 'light' | 'dark';
const THEME_KEY = 'theme_preference';

@Injectable({
  providedIn: 'root'
})
export class ThemeService {
  private renderer: Renderer2;
  public currentTheme = signal<Theme>('dark'); // Default to dark theme

  constructor(rendererFactory: RendererFactory2) {
    this.renderer = rendererFactory.createRenderer(null, null);
    // This effect will run automatically whenever the theme signal changes
    effect(() => {
      this.applyTheme(this.currentTheme());
    });
  }

  /**
   * Loads the saved theme from device storage when the app starts.
   */
  async loadSavedTheme() {
    const { value } = await Preferences.get({ key: THEME_KEY });
    // Set the theme, defaulting to 'dark' if no preference is saved
    this.currentTheme.set((value || 'dark') as Theme);
  }

  /**
   * Toggles the current theme between light and dark and saves the preference.
   */
  toggleTheme() {
    const newTheme = this.currentTheme() === 'dark' ? 'light' : 'dark';
    this.currentTheme.set(newTheme);
    Preferences.set({ key: THEME_KEY, value: newTheme });
  }

  /**
   * Applies the theme to the document body by adding or removing the 'dark' class.
   */
  private applyTheme(theme: Theme) {
    if (theme === 'dark') {
      this.renderer.addClass(document.body, 'dark');
    } else {
      this.renderer.removeClass(document.body, 'dark');
    }
  }
}

