class Product {
  final int? id;
  final String name;
  final String? barcode;
  final double retailPrice;   // سعر المفرق
  final double wholesalePrice; // سعر الجملة
  final double costPrice;      // سعر التكلفة
  final double price;          // السعر المعتمد الافتراضي
  final double quantity;       // الكمية بالمخزن

  Product({
    this.id,
    required this.name,
    this.barcode,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.costPrice,
    double? price,
    required this.quantity,
  }) : price = price ?? retailPrice;

  // 1. ميزة للتوافق مع الشاشات التي تستخدم buyPrice (تعيد سعر التكلفة)
  double get buyPrice => costPrice;

  // 2. ميزة للتوافق مع الشاشات التي تستخدم stockQuantity (تعيد الكمية)
  double get stockQuantity => quantity;

  // تحويل البيانات القادمة من قاعدة البيانات إلى Object
  factory Product.fromJson(Map<String, dynamic> json) {
    final double retail = (json['retail_price'] as num?)?.toDouble() ?? 
                         (json['price'] as num?)?.toDouble() ?? 
                         (json['sell_price'] as num?)?.toDouble() ?? 0.0;
    final double wholesale = (json['wholesale_price'] as num?)?.toDouble() ?? retail;
    final double cost = (json['cost_price'] as num?)?.toDouble() ?? 
                       (json['buy_price'] as num?)?.toDouble() ?? 0.0;
    final double qty = (json['quantity'] as num?)?.toDouble() ?? 
                       (json['stock_quantity'] as num?)?.toDouble() ?? 0.0;

    return Product(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      barcode: json['barcode'] as String?,
      retailPrice: retail,
      wholesalePrice: wholesale,
      costPrice: cost,
      price: retail,
      quantity: qty,
    );
  }

  // دعم التسمية الشهيرة مع sqflite
  factory Product.fromMap(Map<String, dynamic> map) => Product.fromJson(map);

  // تحويل البيانات إلى Map للحفظ والتعديل في DB
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'barcode': barcode,
      'retail_price': retailPrice,
      'wholesale_price': wholesalePrice,
      'cost_price': costPrice,
      'buy_price': costPrice,         // حفظ التكلفة مع الاسمين لضمان عدم حدوث خطأ استعلام
      'price': price,
      'quantity': quantity,
      'stock_quantity': quantity,     // حفظ الكمية مع الاسمين
    };
  }

  Map<String, dynamic> toMap() => toJson();

  // إنشاء نسخة جديدة مع إمكانية تعديل حقول محددة
  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    double? retailPrice,
    double? wholesalePrice,
    double? costPrice,
    double? price,
    double? quantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      costPrice: costPrice ?? this.costPrice,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}
