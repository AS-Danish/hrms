// lib/bindings/HRPerformanceBinding.dart
import 'package:get/get.dart';
import '../controllers/HRPerformanceController.dart';

class HRPerformanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HRPerformanceController>(
          () => HRPerformanceController(),
    );
  }
}