# EcoMarket Flutter API Integration

Esta versión usa el template Flutter y conecta la API de EcoMarket con las mismas variables que ya tienes en Codemagic.

## Lenguaje / stack

- Flutter
- Dart
- Android APK/AAB con Codemagic

## Variables compatibles

Usa las variables actuales:

```text
VITE_ECOMARKET_API_KEY
VITE_LOGIHUB_API_KEY
GOOGLE_MAPS_PLATFORM_KEY
VITE_GOOGLE_MAPS_PLATFORM_KEY
```

Y estas URLs se definen en `codemagic.yaml`:

```text
VITE_ECOMARKET_API_BASE_URL=https://store.ecomarket.uno/api/v2
VITE_ECOMARKET_CLIENT_API_BASE_URL=https://store.ecomarket.uno/api/v2/client
VITE_LOGIHUB_BASE_URL=https://my.logihub.tech/api/v2
APP_URL=https://store.ecomarket.uno
VITE_APP_URL=https://store.ecomarket.uno
```

## Qué se integró

- `lib/services/ecomarket_config.dart`
- `lib/services/ecomarket_api_service.dart`
- `lib/services/logihub_api_service.dart`
- Productos reales en Home usando `/client/products`
- Categorías reales usando `/client/categories`
- Headers reales:
  - `X-ECOMARKET-API-KEY`
  - `Authorization: Bearer`
  - `Accept: application/json`
- LogiHub Service compatible con:
  - `/coverage/locations.php?action=provinces`
  - `/coverage/locations.php?action=cities`
  - `/coverage/locations.php?action=zones`
  - `/nacional/quote.php`

## Comandos locales

```bash
flutter pub get
flutter run \
  --dart-define=VITE_ECOMARKET_API_KEY=TU_KEY_ECOMARKET \
  --dart-define=VITE_LOGIHUB_API_KEY=TU_KEY_LOGIHUB \
  --dart-define=GOOGLE_MAPS_PLATFORM_KEY=TU_KEY_GOOGLE_MAPS \
  --dart-define=VITE_GOOGLE_MAPS_PLATFORM_KEY=TU_KEY_GOOGLE_MAPS
```

## Codemagic

El archivo `codemagic.yaml` ya está listo. Solo necesitas tener en el grupo `ecomarket`:

```text
VITE_ECOMARKET_API_KEY
VITE_LOGIHUB_API_KEY
GOOGLE_MAPS_PLATFORM_KEY
VITE_GOOGLE_MAPS_PLATFORM_KEY
```

Luego ejecuta el workflow:

```text
EcoMarket Flutter Android Debug
```

## Nota importante

Este ZIP integra la API base. El checkout, login visual, Google Places y notificaciones push se pueden conectar en el siguiente paso sobre esta base Flutter limpia.
