// lib/bindings/HRPerformanceBinding.dart
import 'package:get/get.dart';
import 'package:hrms/controllers/EmployeePerformanceController.dart';
import '../controllers/HRPerformanceController.dart';

class EmployeePerformanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeePerformanceController>(
          () => EmployeePerformanceController(),
    );
  }
}