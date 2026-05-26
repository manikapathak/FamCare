import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../models/service_model.dart';
import '../models/slot_model.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';

class ServicePickerScreen extends ConsumerStatefulWidget {
  const ServicePickerScreen({super.key});

  @override
  ConsumerState<ServicePickerScreen> createState() =>
      _ServicePickerScreenState();
}

class _ServicePickerScreenState extends ConsumerState<ServicePickerScreen> {
  List<ServiceModel> services = [];
  List<SlotModel> slots = [];
  ServiceModel? selectedService;
  String? selectedSlot;

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  Future<void> loadServices() async {
    final result = await ApiService().getServices();

    setState(() {
      services = result;
    });
  }

  Future<void> loadSlots() async {
    if (selectedService == null) {
      return;
    }

    final formattedDate = DateFormat(
      "yyyy-MM-dd",
    ).format(
      selectedDate,
    );

    final result = await ApiService().getAvailableSlots(
      selectedService!.id,
      formattedDate,
    );

    setState(() {
      slots = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "FamCARE",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            DropdownButton<ServiceModel>(
              hint: const Text(
                "Select Service",
              ),
              value: selectedService,
              isExpanded: true,
              items: services.map((service) {
                return DropdownMenuItem(
                  value: service,
                  child: Text(
                    service.name,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedService = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  initialDate: selectedDate,
                );

                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Text(
                DateFormat(
                  "dd MMM yyyy",
                ).format(
                  selectedDate,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loadSlots,
              child: const Text(
                "Get Slots",
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: slots.length,
                itemBuilder: (context, index) {
                  final slot = slots[index];

                  return Card(
                    child: ListTile(
                      title: Text(
                        slot.time,
                      ),
                      trailing: selectedSlot == slot.time
                          ? const Icon(
                              Icons.check,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          selectedSlot = slot.time;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedService == null || selectedSlot == null) {
                  return;
                }

                final cartItem = CartItemModel(
                  service: selectedService!,
                  slot: SlotModel(time: selectedSlot!),
                  date: selectedDate,
                );

                ref.read(cartProvider.notifier).addItem(cartItem.toJson());

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CartScreen(),
                  ),
                );
              },
              child: const Text(
                "Add To Cart",
              ),
            )
          ],
        ),
      ),
    );
  }
}
