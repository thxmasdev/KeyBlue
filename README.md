<div align="center">

# KeyBlue

**Teclado Android personalizable de alto rendimiento con motor nativo Canvas 2D, distribuciones inteligentes y privacidad absoluta.**

[![Android](https://img.shields.io/badge/Plataforma-Android%2010%2B-3DDC84?style=flat-square&logo=android&logoColor=white)](https://github.com/thxmasdev/KeyBlue)
[![Licencia](https://img.shields.io/badge/Licencia-Privada%20%2F%20PRO-5B6CFF?style=flat-square)](https://github.com/thxmasdev/KeyBlue)
[![Versión](https://img.shields.io/badge/Versión-v0.1.3-cyan?style=flat-square)](https://github.com/thxmasdev/KeyBlue/releases)

</div>

---

## Visión General

**KeyBlue** nace para resolver un problema recurrente en los teclados móviles actuales: la lentitud, la recolección indiscriminada de datos y la falta de control real sobre el diseño.

A diferencia de los teclados construidos sobre capas web o instancias completas de frameworks pesados, KeyBlue implementa un **motor nativo desacoplado en Kotlin** que dibuja directamente sobre el `Canvas` de Android. El resultado es un teclado que abre en menos de 50 milisegundos, con respuesta táctil inmediata y un consumo de memoria mínimo en segundo plano.

---

## Características Principales

### ⚡ Motor Nativo Canvas 2D
- **Cero latencia de apertura**: Renderizado directo sin intermediarios pesados.
- **Multitáctil fluido**: Respuesta precisa al escribir rápido a dos pulgares.
- **Auto-repetición y gestos**: Borrado rápido progresivo y popups de caracteres secundarios por pulsación prolongada.

### ⌨️ Múltiples Distribuciones
- **QWERTY & AZERTY**: Distribuciones estándar con accesos a puntuación directa.
- **T9 Inteligente (Español & Inglés)**: Algoritmo predictivo offline optimizado por frecuencia de palabras, con soporte nativo para acentos (`á`, `é`, `í`, `ó`, `ú`) y la letra `Ñ` ubicada en la tecla 6 (`MNÑO`).
- **Numérico Extendido**: Distribución dedicada para operaciones financieras y campos de entrada rápida de números.
- **Dvorak & Compacto**: Alternativas ergonómicas para optimizar el espacio en pantallas de diversos tamaños.

### 🎨 Personalización Milimétrica
- **Editor en Tiempo Real**: Ajusta el radio de esquinas, separación entre teclas, altura vertical, grosor y tamaño de tipografía viendo los cambios en vivo.
- **Edición Tecla a Tecla**: Toca cualquier tecla individual dentro del editor para modificar su color de fondo, texto o ancho de manera aislada.
- **Catálogo de 15 Temas de Autor**:
  - *Minimalistas*: Minimal White, Lavender Mist, Material Light, Luxury Gold.
  - *Oscuros & AMOLED*: Midnight Black, AMOLED Pure Black, Material Dark.
  - *Coloridos*: Ocean Blue, Forest Green, Sunset Glow, Crimson Red.
  - *Gaming*: Cyber Neon, Cyberpunk 2077, Gaming RGB Pulse, Glass UI Frost.

### 📂 Perfiles de Teclado
- Guarda múltiples perfiles según tu actividad (Trabajo, Diario, Gaming, T9 Nocturno).
- Duplica, edita, exporta e importa configuraciones completas en formato JSON estándar.

### 🛡️ Privacidad Inviolable por Diseño
- **Sin Keylogging**: No existe registro alguno de palabras escritas, contraseñas, nombres o mensajes.
- **Operación 100% Desconectada**: El servicio del teclado no requiere ni utiliza permisos de red durante la escritura.
- **Detección Automática de Campos Sensibles**: Al ingresar a campos de contraseñas bancarias o formularios privados, el teclado apaga automáticamente cualquier composición predictiva.

---

## Modalidades

| Característica | FREE | PRO |
|---|---|---|
| Distribuciones principales (QWERTY, T9, Numérico) | ✓ | ✓ |
| Temas esenciales (Midnight, AMOLED, Minimal) | ✓ | ✓ |
| Privacidad total y modo offline | ✓ | ✓ |
| Catálogo completo de 15 temas premium | — | ✓ |
| Edición individual por tecla | — | ✓ |
| Perfiles de teclado ilimitados | Máximo 3 | Ilimitados |
| Activación por clave criptográfica (`KEYB-XXXX-XXXX-XXXX`) | — | ✓ |
| Validación offline con firma HMAC local | — | ✓ |

---

## Plataforma Web de Gestión

El ecosistema KeyBlue cuenta con un panel administrativo privado para la generación de licencias, auditoría inmutable de activaciones y publicación de nuevos temas en tiempo real.
