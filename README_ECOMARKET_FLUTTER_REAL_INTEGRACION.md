# EcoMarket Flutter — Integración real v1

Esta versión usa el template Flutter como base y conecta pantallas reales con la API EcoMarket y LogiHub.

## Variables compatibles con Codemagic

Usa las variables que ya tienes configuradas:

```text
VITE_ECOMARKET_API_KEY
VITE_LOGIHUB_API_KEY
GOOGLE_MAPS_PLATFORM_KEY
VITE_GOOGLE_MAPS_PLATFORM_KEY
```

El workflow también define:

```text
VITE_ECOMARKET_API_BASE_URL=https://store.ecomarket.uno/api/v2
VITE_ECOMARKET_CLIENT_API_BASE_URL=https://store.ecomarket.uno/api/v2/client
VITE_LOGIHUB_BASE_URL=https://my.logihub.tech/api/v2
APP_URL=https://store.ecomarket.uno
VITE_APP_URL=https://store.ecomarket.uno
```

## Integrado en esta versión

- Logo e íconos EcoMarket en app.
- Español en onboarding, login, registro, home, carrito, perfil y órdenes.
- Login real con `/client/auth/login`.
- Registro real con `/client/auth/register`.
- Enviar y verificar OTP con `/client/auth/send-otp` y `/client/auth/verify-otp`.
- Guardado local de `customer_token`.
- Productos reales con `/client/products`.
- Categorías reales con `/client/categories`.
- Detalle de producto real con `/client/products/{id}`.
- Carrito local conectado a productos reales.
- Checkout con dirección, provincia, ciudad y zona LogiHub.
- Botón para rellenar dirección exacta usando ubicación del dispositivo.
- Crear orden real con `/client/orders` y `X-Customer-Token`.
- Mis órdenes con `/client/orders`.
- Permiso de notificaciones desde la app.
- Gradle/Kotlin actualizado y sin BOM.

## Nota importante

Las rutas de integración de LogiHub dentro de EcoMarket pueden requerir una key con permisos de `backend_sync` o `admin_integration`. Si la key actual es solo `client_app`, puede listar productos pero fallar en rutas de shipping avanzadas.
