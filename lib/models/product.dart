class Product {
  final int? id;
  final String name;
  final String? barcode;
  final double retailPrice;   // سعر المفرق
  final double wholesalePrice; // سعر الجملة
  final double costPrice;      // سعر التكلفة
  final double price;          // السعر المعتمد الافتراضي
  final double quantity;

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

  // تحويل البيانات القادمة من قاعدة البيانات إلى Object
  factory Product.fromJson(Map<String, dynamic> json) {
    final double retail = (json['retail_price'] as num?)?.toDouble() ?? 
                         (json['price'] as num?)?.toDouble() ?? 0.0;
    final double wholesale = (json['wholesale_price'] as num?)?.toDouble() ?? retail;
    final double cost = (json['cost_price'] as num?)?.toDouble() ?? 0.0;

    return Product(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      barcode: json['barcode'] as String?,
      retailPrice: retail,
      wholesalePrice: wholesale,
      costPrice: cost,
      price: retail,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // تحويل البيانات إلى Map للحفظ والتعديل في DB
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'barcode': barcode,
      'retail_price': retailPrice,
      'wholesale_price': wholesalePrice,
      'cost_price': costPrice,
      'price': price,
      'quantity': quantity,
    };
  }

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
