import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'io.myjapanese.manabinotomo',
  appName: 'Tomo',
  webDir: 'www',
  plugins: {
    SplashScreen: {
      launchShowDuration: 1000,
      launchAutoHide: true,
      backgroundColor: '#121212',
      androidSplashResourceName: 'splash',
      androidScaleType: 'CENTER_CROP',
      showSpinner: false,
      splashFullScreen: true,
      splashImmersive: true,
    },
    Keyboard: {
      resizeOnFullScreen: false // Prevents problematic resizing with keyboard
    },
    EdgeToEdge: {
      backgroundColor: '#2a2a2a' // Optional: Customize background behind system bars
    },
    // Add this ScreenOrientation plugin configuration
    ScreenOrientation: {
      orientation: 'portrait-primary'
    }
  },
  android: {
    adjustMarginsForEdgeToEdge: 'force' // Helps layout compensate
  }
};

export default config;
