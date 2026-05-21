class Transaction {
  final int id;
  final int vehicleId;
  final String vehicleMake;
  final String vehicleModel;
  final int vehicleYear;
  final String vehicleColor;
  final String buyerName;
  final String buyerPhone;
  final String buyerIdNumber;
  final String paymentMethod;
  final int salePrice;
  final int downPayment;
  final int installmentMonths;
  final int installmentAmount;
  final String notes;
  final String createdBy;
  final DateTime soldAt;

  Transaction({
    required this.id,
    required this.vehicleId,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.vehicleColor,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerIdNumber,
    required this.paymentMethod,
    required this.salePrice,
    required this.downPayment,
    required this.installmentMonths,
    required this.installmentAmount,
    required this.notes,
    required this.createdBy,
    required this.soldAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: (json['id'] as num).toInt(),
      vehicleId: (json['vehicle_id'] as num).toInt(),
      vehicleMake: json['vehicle_make'] ?? '',
      vehicleModel: json['vehicle_model'] ?? '',
      vehicleYear: (json['vehicle_year'] as num?)?.toInt() ?? 0,
      vehicleColor: json['vehicle_color'] ?? '',
      buyerName: json['buyer_name'] ?? '',
      buyerPhone: json['buyer_phone'] ?? '',
      buyerIdNumber: json['buyer_id_number'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      salePrice: (json['sale_price'] as num?)?.toInt() ?? 0,
      downPayment: (json['down_payment'] as num?)?.toInt() ?? 0,
      installmentMonths: (json['installment_months'] as num?)?.toInt() ?? 0,
      installmentAmount: (json['installment_amount'] as num?)?.toInt() ?? 0,
      notes: json['notes'] ?? '',
      createdBy: json['created_by'] ?? '',
      soldAt: json['sold_at'] != null
          ? DateTime.parse(json['sold_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'vehicle_id': vehicleId,
    'buyer_name': buyerName,
    'buyer_phone': buyerPhone,
    'buyer_id_number': buyerIdNumber,
    'payment_method': paymentMethod,
    'sale_price': salePrice,
    'down_payment': downPayment,
    'installment_months': installmentMonths,
    'installment_amount': installmentAmount,
    'notes': notes,
  };
}
