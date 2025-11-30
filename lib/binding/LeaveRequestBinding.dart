import 'package:get/get.dart';
import '../controllers/LeaveRequestController.dart';

class LeaveRequestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LeaveRequestController>(() => LeaveRequestController());
  }
}