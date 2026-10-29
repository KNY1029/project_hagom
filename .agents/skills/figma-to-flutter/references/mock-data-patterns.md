# Mock Data Patterns
## Modelos complejos para pantallas Flutter desde Figma

---

## Principio base

Cada pantalla tiene exactamente **un** modelo raíz que contiene toda la data que se ve en pantalla.
El modelo incluye siempre dos factories: `mock()` y `fromJson()`.

---

## Patrón: Lista de ítems

```dart
class ProductListModel {
  final String pageTitle;
  final List<ProductItemModel> items;
  final bool isLoading;

  const ProductListModel({
    required this.pageTitle,
    required this.items,
    this.isLoading = false,
  });

  factory ProductListModel.mock() {
    return ProductListModel(
      pageTitle: 'Productos',
      items: List.generate(6, (i) => ProductItemModel.mock(id: i)),
    );
  }

  factory ProductListModel.fromJson(Map<String, dynamic> json) {
    return ProductListModel(
      pageTitle: json['title'] as String,
      items: (json['items'] as List)
          .map((e) => ProductItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProductItemModel {
  final int id;
  final String name;
  final String imageUrl;
  final double price;

  const ProductItemModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
  });

  factory ProductItemModel.mock({int id = 0}) {
    return ProductItemModel(
      id: id,
      name: 'Producto $id',
      imageUrl: 'https://picsum.photos/seed/$id/200/200',
      price: 99.99 + id,
    );
  }

  factory ProductItemModel.fromJson(Map<String, dynamic> json) {
    return ProductItemModel(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
}
```

---

## Patrón: Perfil de usuario

```dart
class UserProfileModel {
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? bio;

  const UserProfileModel({
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.bio,
  });

  factory UserProfileModel.mock() {
    return const UserProfileModel(
      displayName: 'María García',
      email: 'maria@example.com',
      avatarUrl: 'https://picsum.photos/seed/user/100/100',
      bio: 'Diseñadora UX apasionada por los detalles.',
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      displayName: json['display_name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
    );
  }
}
```

---

## Patrón: Pantalla con múltiples secciones

Cuando el diseño tiene secciones distintas (hero + lista + banner, etc.):

```dart
class HomeScreenModel {
  final HeroSectionModel hero;
  final List<CategoryModel> categories;
  final List<ProductItemModel> featured;
  final BannerModel? promoBanner;

  const HomeScreenModel({
    required this.hero,
    required this.categories,
    required this.featured,
    this.promoBanner,
  });

  factory HomeScreenModel.mock() {
    return HomeScreenModel(
      hero: HeroSectionModel.mock(),
      categories: List.generate(4, (i) => CategoryModel.mock(id: i)),
      featured: List.generate(3, (i) => ProductItemModel.mock(id: i)),
      promoBanner: BannerModel.mock(),
    );
  }

  factory HomeScreenModel.fromJson(Map<String, dynamic> json) {
    return HomeScreenModel(
      hero: HeroSectionModel.fromJson(json['hero'] as Map<String, dynamic>),
      categories: (json['categories'] as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      featured: (json['featured'] as List)
          .map((e) => ProductItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      promoBanner: json['promo_banner'] != null
          ? BannerModel.fromJson(json['promo_banner'] as Map<String, dynamic>)
          : null,
    );
  }
}
```

---

## Patrón: Estados de UI

Cuando el diseño muestra estados (vacío, error, cargando):

```dart
class OrderListModel {
  final List<OrderModel> orders;
  final bool isEmpty;

  const OrderListModel({
    required this.orders,
    this.isEmpty = false,
  });

  /// Mock — estado lleno
  factory OrderListModel.mock() {
    return OrderListModel(
      orders: List.generate(3, (i) => OrderModel.mock(id: i)),
    );
  }

  /// Mock — estado vacío (para testing del empty state del diseño)
  factory OrderListModel.mockEmpty() {
    return const OrderListModel(orders: [], isEmpty: true);
  }

  factory OrderListModel.fromJson(Map<String, dynamic> json) {
    final items = (json['orders'] as List)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return OrderListModel(orders: items, isEmpty: items.isEmpty);
  }
}
```

---

## Reglas generales

1. **Un modelo por pantalla** — no compartir modelos entre pantallas distintas
2. **Los modelos son inmutables** — usar `const` constructors
3. **Nullable solo si el diseño lo muestra** — si en Figma hay variante sin ese campo, hacerlo nullable
4. **Mock data debe reflejar el diseño** — si el diseño tiene un título largo, el mock debe ser largo
5. **Imágenes mock** — usar `picsum.photos/seed/[id]/[w]/[h]` para consistencia
6. **No lógica de negocio** — los modelos solo estructuran data, no calculan ni filtran
