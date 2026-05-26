class ServiceModel {

  final int id;
  final String name;
  final int durationMinutes;
  final double price;

  ServiceModel({

    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price

  });

  factory ServiceModel.fromJson(
      Map<String,dynamic> json
      ){

    return ServiceModel(

      id: json['id'],

      name: json['name'],

      durationMinutes:
      json['duration_minutes'],

      price:
      json['price'].toDouble(),

    );
  }
}