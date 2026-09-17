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
    double? retailPrice,
    double? wholesalePrice,
    double? costPrice,
    double? buyPrice,        // ممرر اختياري للتوافق مع الشاشات القديمة
    double? price,
    double? quantity,
    double? stockQuantity,   // ممرر اختياري للتوافق مع الشاشات القديمة
  })  : costPrice = costPrice ?? buyPrice ?? 0.0,
        retailPrice = retailPrice ?? price ?? 0.0,
        wholesalePrice = wholesalePrice ?? retailPrice ?? price ?? 0.0,
        price = price ?? retailPrice ?? 0.0,
        quantity = quantity ?? stockQuantity ?? 0.0;

  double get buyPrice => costPrice;
  double get stockQuantity => quantity;

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

  factory Product.fromMap(Map<String, dynamic> map) => Product.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'barcode': barcode,
      'retail_price': retailPrice,
      'wholesale_price': wholesalePrice,
      'cost_price': costPrice,
      'buy_price': costPrice,
      'price': price,
      'quantity': quantity,
      'stock_quantity': quantity,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}
