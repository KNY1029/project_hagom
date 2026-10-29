# Design System Mapping Guide
## Figma Component Types → Flutter Widget Patterns

---

## Formularios / Inputs

| Figma | Flutter DS widget | Notas |
|---|---|---|
| Text Field / Input | `AppTextField` | Pasar `hintText`, `label`, `validator` |
| Dropdown | `AppDropdown` | Pasar `items` como lista del modelo |
| Checkbox | `AppCheckbox` | |
| Radio Button | `AppRadioGroup` | |
| Toggle / Switch | `AppSwitch` | |
| Date Picker | `AppDatePicker` | |

**Regla:** Nunca usar `TextField` nativo de Flutter si existe widget del DS.

---

## Botones / CTAs

| Figma variant | Flutter DS widget | Props clave |
|---|---|---|
| Primary | `PrimaryButton` | `onPressed`, `label`, `isLoading` |
| Secondary | `SecondaryButton` | |
| Ghost / Text | `GhostButton` | |
| Icon Button | `AppIconButton` | `icon`, `onPressed` |
| FAB | `AppFAB` | |

**Regla:** El estado `disabled` en Figma → pasar `onPressed: null`.
**Regla:** El estado `loading` en Figma → pasar `isLoading: true`.

---

## Navegación

| Figma | Flutter | Notas |
|---|---|---|
| Bottom Navigation Bar | `AppBottomNavBar` | Items del modelo |
| Top App Bar | `AppBar` del DS | No usar `AppBar` nativo |
| Tab Bar | `AppTabBar` | |
| Drawer | `AppDrawer` | |
| Back button | Parte del `AppBar` | No agregar manualmente |

---

## Listas y Cards

| Figma | Flutter | Notas |
|---|---|---|
| List Item | `AppListTile` | |
| Card | `AppCard` | Usar variante correcta |
| Grid Item | Widget del DS correspondiente | |
| Carousel | `AppCarousel` | |

**Regla para listas:** Siempre usar `ListView.builder` con datos del modelo, nunca hardcodear ítems.

---

## Overlays / Modales

| Figma | Flutter | Cómo invocar |
|---|---|---|
| Bottom Sheet | `AppBottomSheet.show(context, ...)` | |
| Dialog / Alert | `AppDialog.show(context, ...)` | |
| Snackbar / Toast | `AppSnackbar.show(context, ...)` | |
| Tooltip | `AppTooltip` | |

**Regla:** Los overlays no son pantallas, no se incluyen en la screen directamente. Se invocan via helpers del DS.

---

## Imágenes y Assets

| Figma | Flutter | Notas |
|---|---|---|
| Image con URL | `AppNetworkImage` | Pasar URL del modelo |
| Image local/asset | `AppAssetImage` | Pasar asset path |
| Avatar / Profile pic | `AppAvatar` | `imageUrl` o `initials` |
| Icon (DS icons) | `AppIcon(AppIcons.nombreIcono)` | Nunca usar `Icons.*` nativo |
| Illustration | `SvgPicture.asset(...)` | Del catálogo de assets |

**Regla:** Todos los íconos deben venir del catálogo de íconos del DS. Si un ícono de Figma no está en el catálogo, reportarlo en la auditoría.

---

## Tokens de Spacing

Al extraer padding/margin de Figma, mapear a tokens del DS:

```dart
// En lugar de:
padding: EdgeInsets.all(16)

// Usar tokens del DS:
padding: EdgeInsets.all(AppSpacing.md)  // si 16 == md en el DS
```

Valores comunes de spacing:
- 4px → `AppSpacing.xs`
- 8px → `AppSpacing.sm`  
- 12px → `AppSpacing.smMd`
- 16px → `AppSpacing.md`
- 24px → `AppSpacing.lg`
- 32px → `AppSpacing.xl`
- 48px → `AppSpacing.xxl`

**Nota:** Si el DS de este proyecto usa nombres diferentes, usar los del proyecto. Estos son ejemplos.

---

## Tipografía

Al extraer estilos de texto de Figma:

```dart
// Nunca:
TextStyle(fontSize: 24, fontWeight: FontWeight.bold)

// Siempre:
AppTextStyles.heading1
AppTextStyles.bodyMedium
AppTextStyles.caption
```

Mapear por jerarquía visual del diseño, no por valor numérico.

---

## Colores

```dart
// Nunca:
Color(0xFF1A73E8)
Colors.blue

// Siempre:
AppColors.primary
AppColors.surface
AppColors.textPrimary
AppColors.error
```

Si el color de Figma no tiene token en el DS → reportar en auditoría como inconsistencia de diseño.
