class ContentConstants {
  static const bundledManifest = 'assets/data/content-manifest.json';
  static const legacyRemoteBase =
      'https://gist.githubusercontent.com/naingminhtetoo/aa317f1afb33303017bc78254b110198/raw/';
  // Enable only once a versioned manifest and matching level files are published.
  static const remoteBase = String.fromEnvironment('TOMO_CONTENT_BASE_URL');
}
