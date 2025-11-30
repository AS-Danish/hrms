import 'package:get/get.dart';
import '../controllers/HRLeaveManagementController.dart';

class HRLeaveManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HRLeaveManagementController>(
          () => HRLeaveManagementController(),
    );
  }
}