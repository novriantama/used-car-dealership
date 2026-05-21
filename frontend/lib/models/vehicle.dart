class Vehicle {
  final int id;
  final String make;
  final String model;
  final int year;
  final int price; // IDR pricing (fits in 64-bit int / standard Dart int)
  final String transmission; // 'Manual' or 'Automatic'
  final String fuelType;
  final int mileage;
  final int engineCapacity;
  final String color;
  final String plateType; // 'Ganjil' or 'Genap'
  final String taxStatus; // 'Aktif' or 'Kedaluwarsa'
  final String taxExpiryDate; // YYYY-MM-DD
  final String location;
  final int inspectionEngine;
  final int inspectionInterior;
  final int inspectionExterior;
  final String inspectionNotes;
  final String status; // 'Available', 'Reserved', 'Sold'
  final List<String> imageUrls;

  Vehicle({
    this.id = 0,
    required this.make,
    required this.model,
    required this.year,
    required this.price,
    required this.transmission,
    required this.fuelType,
    required this.mileage,
    required this.engineCapacity,
    required this.color,
    required this.plateType,
    required this.taxStatus,
    required this.taxExpiryDate,
    required this.location,
    this.inspectionEngine = 100,
    this.inspectionInterior = 100,
    this.inspectionExterior = 100,
    this.inspectionNotes = '',
    this.status = 'Available',
    required this.imageUrls,
  });

  int get averageInspectionScore =>
      ((inspectionEngine + inspectionInterior + inspectionExterior) / 3).round();

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 0,
      price: (json['price'] as num?)?.toInt() ?? 0,
      transmission: json['transmission'] ?? '',
      fuelType: json['fuel_type'] ?? '',
      mileage: json['mileage'] ?? 0,
      engineCapacity: json['engine_capacity'] ?? 0,
      color: json['color'] ?? '',
      plateType: json['plate_type'] ?? '',
      taxStatus: json['tax_status'] ?? '',
      taxExpiryDate: json['tax_expiry_date'] ?? '',
      location: json['location'] ?? '',
      inspectionEngine: json['inspection_engine'] ?? 100,
      inspectionInterior: json['inspection_interior'] ?? 100,
      inspectionExterior: json['inspection_exterior'] ?? 100,
      inspectionNotes: json['inspection_notes'] ?? '',
      status: json['status'] ?? 'Available',
      imageUrls: List<String>.from(json['image_urls'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'price': price,
      'transmission': transmission,
      'fuel_type': fuelType,
      'mileage': mileage,
      'engine_capacity': engineCapacity,
      'color': color,
      'plate_type': plateType,
      'tax_status': taxStatus,
      'tax_expiry_date': taxExpiryDate,
      'location': location,
      'inspection_engine': inspectionEngine,
      'inspection_interior': inspectionInterior,
      'inspection_exterior': inspectionExterior,
      'inspection_notes': inspectionNotes,
      'status': status,
      'image_urls': imageUrls,
    };
  }
}
