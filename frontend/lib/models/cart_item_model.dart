import 'package:intl/intl.dart';
import 'service_model.dart';
import 'slot_model.dart';

class CartItemModel {
  final ServiceModel service;
  final SlotModel slot;
  final DateTime date;

  CartItemModel({
    required this.service,
    required this.slot,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'service_id': service.id,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'start_time': slot.time,
    };
  }
}
