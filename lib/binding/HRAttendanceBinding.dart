// lib/binding/HRAttendanceBinding.dart
import 'package:get/get.dart';
import '../controllers/HRAttendanceController.dart';

class HRAttendanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HRAttendanceController>(() => HRAttendanceController());
  }
}