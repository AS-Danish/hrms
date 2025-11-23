import 'package:get/get.dart';

import '../controllers/HRManagementController.dart';

class HRManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HRManagementController());
  }
}