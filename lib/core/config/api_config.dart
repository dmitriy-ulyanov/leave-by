const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8765');

const String storageMode = String.fromEnvironment('STORAGE', defaultValue: 'remote');

const bool showSemanticsOverlay = bool.fromEnvironment('SEMANTICS_DEBUG');
