import 'package:dio/dio.dart';
import '../models/service_model.dart';
import '../models/slot_model.dart';

class ApiService {

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.6:8000',
    ),
  );

  Future<List<ServiceModel>> getServices() async {

    final response = await _dio.get(
      '/services/'
    );

    return (response.data as List)
        .map(
          (x)=>ServiceModel.fromJson(x)
    ).toList();

  }

  Future<List<SlotModel>>
  getAvailableSlots(
      int serviceId,
      String date
      ) async {

    final response =
    await _dio.get(

      '/slots/available',

      queryParameters: {

        'service_id':serviceId,
        'date':date,

      },
    );

    return (response.data as List)
        .map(
            (x)=>SlotModel.fromJson(x)
    ).toList();
  }

  Future<List<Map<String, dynamic>>> getCaregivers() async {

    final response =
        await _dio.get('/caregivers', queryParameters: {
          "service_id": 1
        });

    return List<Map<String, dynamic>>.from(response.data);

  }

  Future<Response> checkoutCart(
        int patientId,
        List<Map<String,dynamic>> items
    ) async {

    final requestData = {

        "patient_id": patientId,
        "items": items,

    };

   final response =
       await _dio.post(

     "/cart/checkout",

     data: requestData,

   );

   return response;
 }
}