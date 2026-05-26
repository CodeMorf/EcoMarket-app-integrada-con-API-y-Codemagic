class EcoMarketConfig {
  static const appUrl = String.fromEnvironment(
    'APP_URL',
    defaultValue: 'https://store.ecomarket.uno',
  );

  static const viteAppUrl = String.fromEnvironment(
    'VITE_APP_URL',
    defaultValue: 'https://store.ecomarket.uno',
  );

  static const apiBaseUrl = String.fromEnvironment(
    'VITE_ECOMARKET_API_BASE_URL',
    defaultValue: 'https://store.ecomarket.uno/api/v2',
  );

  static const clientApiBaseUrl = String.fromEnvironment(
    'VITE_ECOMARKET_CLIENT_API_BASE_URL',
    defaultValue: 'https://store.ecomarket.uno/api/v2/client',
  );

  // Compatible con las variables que ya tienes en Codemagic.
  static const ecomarketApiKey = String.fromEnvironment('VITE_ECOMARKET_API_KEY');

  static const logihubBaseUrl = String.fromEnvironment(
    'VITE_LOGIHUB_BASE_URL',
    defaultValue: 'https://my.logihub.tech/api/v2',
  );

  static const logihubApiKey = String.fromEnvironment('VITE_LOGIHUB_API_KEY');

  static const googleMapsPlatformKey = String.fromEnvironment('GOOGLE_MAPS_PLATFORM_KEY');
  static const viteGoogleMapsPlatformKey = String.fromEnvironment('VITE_GOOGLE_MAPS_PLATFORM_KEY');

  static bool get hasEcoMarketKey => ecomarketApiKey.trim().isNotEmpty;
  static bool get hasLogiHubKey => logihubApiKey.trim().isNotEmpty;

  static String joinUrl(String baseUrl, String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$base$cleanPath';
  }
}
