class SlotModel{

  final String time;

  SlotModel({
    required this.time
  });

  factory SlotModel.fromJson(
      dynamic json
      ){

    return SlotModel(
      time: json
    );
  }
}