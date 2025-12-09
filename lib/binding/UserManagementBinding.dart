import 'package:get/get.dart';
import 'package:hrms/controllers/UserManagementController.dart';

class UsermanagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserManagementController>(
          () => UserManagementController(),
    );
  }
}