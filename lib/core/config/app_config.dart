class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'ATMA_API_BASE_URL',
    defaultValue: 'https://api.atma.biz.id',
  );

  static const Duration requestTimeout = Duration(seconds: 8);
  static const Duration dashboardPollingInterval = Duration(seconds: 5);
}
