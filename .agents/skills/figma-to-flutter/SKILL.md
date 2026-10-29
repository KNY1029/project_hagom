---
name: figma-to-flutter
description: >
  Use this skill whenever the user wants to translate a Figma design, frame, screen, or component into Flutter code. Triggers include: "pasa este diseño a Flutter", "convierte este frame", "implementa esta pantalla desde Figma", "traduce el diseño a código", "pixel perfect desde Figma", "implementa según el diseño", or any time the user shares a Figma link, screenshot, or dev-mode spec and wants Flutter output. Also triggers when auditing which Figma design system components are missing Flutter widget implementations. This skill handles ONLY visual fidelity and design translation — for architecture, folder structure, state management, and performance, defer to the companion architecture/layout/performance skills documented in this repo.
---

# Figma → Flutter Skill

Este skill traduce diseños de Figma a código Flutter **pixel-perfect**, usando fielmente los componentes del design system. No inventa nada: si un componente no existe aún en Flutter, lo reporta en la auditoría.

---

## Scope de este skill

| ✅ Este skill hace | ❌ Defer a otro skill |
|---|---|
| Traducción visual fiel del diseño | Arquitectura de carpetas → `flutter-apply-architecture-best-practices` |
| Uso correcto de tokens del DS | Gestión de estado → `flutter-apply-architecture-best-practices` |
| Mapeo Figma component → Flutter widget | Responsive/adaptive layout → `flutter-build-responsive-layout` |
| Mock data con Model + factory | Optimización de renders → `mindrally/skills@flutter` |
| Auditoría de componentes faltantes | Navegación y routing → `flutter-apply-architecture-best-practices` |
| Extracción de specs desde MCP Figma | |

## Companion skills

Para una implementación Flutter lista para producción, este skill debe trabajar junto con:

- `flutter-apply-architecture-best-practices` → estructura de capas, límites del feature, arquitectura y disciplina de composición
- `flutter-build-responsive-layout` → responsive/adaptive layout, breakpoints y comportamiento multi-device
- `mindrally/skills@flutter` → fallback actual instalable para guía Flutter general, incluyendo optimización de rebuilds, listas, imágenes y render cost

Si alguno no está disponible, continuar solo con la traducción visual y dejar explícito en el reporte final qué partes quedaron fuera del alcance.

---

## Paso 0: Verificar MCP de Figma

Antes de cualquier trabajo, verificar que el MCP de Figma está disponible.

```
Si NO detectas herramientas del MCP de Figma disponibles:
  → Informar al usuario: "Para usar este skill necesitas conectar el MCP de Figma.
     Ve a la configuración de tu cliente/harness → Conectores/MCP y conecta Figma.
     Una vez conectado, comparte el link del frame o abre el archivo en Figma."
  → No continuar hasta confirmar conexión
```

---

## Paso 1: Capturar el diseño desde Figma

Usar el MCP de Figma para extraer la información del frame. Hacerlo en este orden:

### 1a. Obtener screenshot del frame
Capturar imagen visual del frame para referencia pixel-perfect.

### 1b. Obtener especificaciones del Dev Mode
Extraer desde el MCP o desde la vista dev de Figma:
- **Dimensiones**: width, height de cada elemento
- **Espaciado**: padding, margin, gap entre elementos
- **Colores**: valores exactos o referencias a tokens del DS
- **Tipografía**: font family, size, weight, line height, letter spacing
- **Componentes usados**: nombre exacto de cada componente del DS
- **Assets**: íconos, imágenes, ilustraciones (con sus nombres en Figma)

### 1c. Identificar la jerarquía visual
Mapear el árbol de layers de Figma → estructura de widgets Flutter:
```
Frame (pantalla)
  └── Section/Group → Column/Row/Stack
        └── Component instance → Widget del DS
              └── Text/Icon/Image → Widget primitivo
```

---

## Paso 2: Auditoría del Design System

Antes de escribir código, hacer un inventario:

### Componentes encontrados en el diseño:
Listar cada componente de Figma encontrado en el frame.

### Estado de cada componente:
```
✅ LISTO     → Widget Flutter existe, usar directamente
⚠️  PARCIAL  → Widget existe pero faltan variantes/props
❌ FALTANTE  → No existe widget Flutter, necesita crearse
```

### Output de auditoría (mostrar siempre antes de codificar):
```
📋 AUDITORÍA DE COMPONENTES — [NombrePantalla]
─────────────────────────────────────────────
✅ PrimaryButton       → PrimaryButton widget
✅ AppTextField        → AppTextField widget  
⚠️  CardProduct        → ProductCard existe, falta variante "compact"
❌ RatingStars         → No encontrado en Flutter, debe crearse
❌ PriceTag            → No encontrado en Flutter, debe crearse
─────────────────────────────────────────────
Listo para implementar: 2/5 componentes
Necesitan atención: 3/5 componentes

¿Cómo proceder?
[A] Implementar solo con componentes existentes + placeholders para los faltantes
[B] Crear los componentes faltantes primero, luego implementar la pantalla
[C] Solo mostrarme la auditoría por ahora
```

**Esperar respuesta del usuario antes de continuar.**

---

## Paso 3: Estructura de archivos de salida

Siguiendo la estructura definida en el companion de arquitectura (no redefinir aquí):

```
lib/
  features/
    [feature_name]/
      presentation/
        screens/
          [screen_name]_screen.dart      ← pantalla principal
        widgets/
          [component_name]_widget.dart   ← widgets locales al feature
      data/
        models/
          [screen_name]_model.dart       ← mock data + factories
```

Si el companion de arquitectura define una estructura diferente, seguirla.

---

## Paso 4: Generar el código

### Reglas de traducción fiel

**SIEMPRE:**
- Usar el widget del DS que corresponde al componente de Figma (por nombre)
- Respetar dimensiones exactas: `SizedBox(width: X, height: Y)`
- Respetar espaciados exactos: `padding: EdgeInsets.fromLTRB(...)` o `gap`
- Usar los tokens del DS para colores: `AppColors.primary`, nunca `Color(0xFF...)`
- Usar los tokens del DS para tipografía: `AppTextStyles.heading1`, nunca `TextStyle(...)` inline
- Separar widgets que se repiten en archivos propios en `/widgets/`

**NUNCA:**
- Inventar un componente que no existe en el DS
- Aproximar colores o fuentes ("es parecido a...")
- Cambiar el layout visual por conveniencia técnica
- Hardcodear strings sin pasar por el modelo de datos

### Template de pantalla
```dart
// [screen_name]_screen.dart
// Generated from Figma: [Frame name / link]
// DS components used: [lista]
// Pending components: [lista de ❌]

import 'package:flutter/material.dart';
// imports del DS
// imports locales

class [ScreenName]Screen extends StatelessWidget {
  final [ScreenName]Model data;
  
  const [ScreenName]Screen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // implementación fiel al diseño
    );
  }
}
```

### Template de modelo con mock data
```dart
// [screen_name]_model.dart
// Mock data — ready to be replaced by real backend data

class [ScreenName]Model {
  final String title;
  // ... propiedades según el diseño

  const [ScreenName]Model({
    required this.title,
    // ...
  });

  /// Mock data factory — replace with real data source
  factory [ScreenName]Model.mock() {
    return [ScreenName]Model(
      title: 'Mock Title',
      // valores que reflejan el diseño de Figma
    );
  }

  /// From JSON — for backend integration
  factory [ScreenName]Model.fromJson(Map<String, dynamic> json) {
    return [ScreenName]Model(
      title: json['title'] as String,
      // ...
    );
  }
}
```

---

## Paso 5: Reporte final

Al terminar cada pantalla, generar un reporte:

```
✅ IMPLEMENTACIÓN COMPLETA — [NombrePantalla]
─────────────────────────────────────────────
Archivos generados:
  📄 [screen_name]_screen.dart
  📄 [screen_name]_model.dart
  📄 widgets/[x]_widget.dart (si aplica)

Componentes DS usados: X
Componentes pendientes de crear: Y
  ❌ RatingStars — sugerido: crear en /shared/widgets/
  ❌ PriceTag    — sugerido: crear en /shared/widgets/

Mock data: ✅ incluida con factory
Backend ready: ✅ fromJson listo para conectar
─────────────────────────────────────────────
```

---

## Consultar referencias adicionales

Lee estos archivos cuando necesites contexto específico:

- `references/ds-mapping-guide.md` → Cuando necesites reglas de mapeo Figma→Flutter para tipos de componentes específicos (formularios, navegación, listas, overlays)
- `references/mock-data-patterns.md` → Cuando el modelo de datos sea complejo (listas anidadas, estados múltiples, imágenes, etc.)
