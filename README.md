# 📺 Micanal IPTV (WGNet)

**Micanal IPTV** es una aplicación moderna, liviana y optimizada para la reproducción de televisión en vivo mediante el protocolo Xtream Codes API. Desarrollada en **Flutter** y orientada al rendimiento fluido en dispositivos Android.

---

## 🚀 Características Principales

- 🔐 **Autenticación Persistente:** Inicio de sesión automático y guardado seguro de credenciales con `shared_preferences`.
- ⚡ **Inicio Ultrarrápido:** Almacenamiento en caché local de la lista de canales para una carga casi instantánea al abrir la app.
- 🎬 **Reproducción de Alto Rendimiento:** Integración con `media_kit` para un streaming estable y de baja latencia en streams HLS/m3u8.
- 📱 **UX/UI Optimizada:**
  - Modo pantalla completa con controles flotantes inteligentes que se ocultan automáticamente tras 3 segundos de inactividad.
  - Navegación segura con `PopScope` que evita el cierre accidental de la aplicación al usar el botón de retroceso físico de Android.
  - Orientación fija en modo horizontal (*Landscape*) para una experiencia nativa de televisión.
- 💡 **Prevención de Suspensión:** Mantiene la pantalla encendida automáticamente durante la reproducción mediante `wakelock_plus`.

---

## 🛠️ Tecnologías y Librerías Utilizadas

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Motor de Video:** `media_kit` & `media_kit_video`
- **Persistencia de Datos:** `shared_preferences`
- **Gestión de Pantalla:** `wakelock_plus` & `flutter/services`
- **Protocolo de Streaming:** Xtream Codes Player API (`http`)

---

## 📦 Estructura del Proyecto

```text
wgnet_iptv/
├── android/               # Configuración nativa y manifiesto de Android
├── assets/                # Logos e imágenes del proyecto
├── lib/
│   └── main.dart          # Lógica principal, Splash, Login y Reproductor
└── pubspec.yaml           # Configuración y dependencias del proyecto
