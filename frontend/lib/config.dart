class Config {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://fuseguard.onrender.com/api',
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://fuseguard.onrender.com/',
  );
}
