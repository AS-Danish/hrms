import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/onboardingController.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});



  @override
  Widget build(BuildContext context) {

    final OnboardingController controller = Get.put(OnboardingController());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_add_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Complete Your Profile",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Help us know you better",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Indicator
              Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= controller.currentStep.value
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              )),

              const SizedBox(height: 24),

              // Content Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Obx(() {
                          switch (controller.currentStep.value) {
                            case 0:
                              return _PersonalDetailsStep(controller: controller);
                            case 1:
                              return _VerificationDetailsStep(controller: controller);
                            case 2:
                              return _BankDetailsStep(controller: controller);
                            case 3:
                              return _EmploymentDetailsStep(controller: controller);
                            default:
                              return const SizedBox();
                          }
                        }),
                      ),

                      // Navigation Buttons
                      Obx(() => Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            if (controller.currentStep.value > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: controller.previousStep,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Previous",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ),
                              ),
                            if (controller.currentStep.value > 0) const SizedBox(width: 16),
                            Expanded(
                              flex: controller.currentStep.value > 0 ? 1 : 1,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : controller.nextStep,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: const Color(0xFF3B82F6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : Text(
                                  controller.currentStep.value < 3 ? "Next" : "Complete",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Personal Details Step
class _PersonalDetailsStep extends StatelessWidget {
  final OnboardingController controller;

  const _PersonalDetailsStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Personal Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: controller.fullNameController,
            label: "Full Name *",
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: controller.dateOfBirthController,
            label: "Date of Birth *",
            icon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                controller.dateOfBirthController.text = "${date.day}/${date.month}/${date.year}";
              }
            },
          ),
          const SizedBox(height: 16),
          Obx(() => _buildGenderSelector(controller)),
          const SizedBox(height: 16),
          _buildTextField(
            controller: controller.phoneController,
            label: "Phone Number *",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: controller.addressController,
            label: "Address *",
            icon: Icons.home_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: controller.cityController,
                  label: "City",
                  icon: Icons.location_city_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: controller.stateController,
                  label: "State",
                  icon: Icons.map_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: controller.zipCodeController,
            label: "ZIP Code",
            icon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}

// Verification Details Step
class _VerificationDetailsStep extends StatelessWidget {
  final OnboardingController controller;

  const _VerificationDetailsStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Verification Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: controller.panController,
            label: "PAN Number *",
            icon: Icons.credit_card_outlined,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: controller.aadharController,
            label: "Aadhar Number *",
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: controller.passportController,
            label: "Passport Number (Optional)",
            icon: Icons.book_outlined,
            keyboardType: TextInputType.text,
          ),
        ],
      ),
    );
  }
}

// Bank Details Step
class _BankDetailsStep extends StatelessWidget {
  final OnboardingController controller;

  const _BankDetailsStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bank Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: controller.bankNameController,
            label: "Bank Name *",
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: controller.accountNumberController,
            label: "Account Number *",
            icon: Icons.numbers_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: controller.ifscController,
            label: "IFSC Code *",
            icon: Icons.code_outlined,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: controller.accountHolderNameController,
            label: "Account Holder Name *",
            icon: Icons.person_outline,
          ),
        ],
      ),
    );
  }
}

// Employment Details Step
class _EmploymentDetailsStep extends StatelessWidget {
  final OnboardingController controller;

  const _EmploymentDetailsStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Employment Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: controller.departmentController,
            label: "Department *",
            icon: Icons.business_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: controller.designationController,
            label: "Designation *",
            icon: Icons.work_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: controller.joiningDateController,
            label: "Joining Date *",
            icon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                controller.joiningDateController.text = "${date.day}/${date.month}/${date.year}";
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: controller.employeeIdController,
            label: "Employee ID (Optional)",
            icon: Icons.badge_outlined,
          ),
        ],
      ),
    );
  }
}

// Helper Widgets
Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType? keyboardType,
  int maxLines = 1,
  bool readOnly = false,
  VoidCallback? onTap,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    ],
  );
}

Widget _buildGenderSelector(OnboardingController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Gender *",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _GenderOption(
              label: "Male",
              icon: Icons.male,
              isSelected: controller.selectedGender.value == "Male",
              onTap: () => controller.selectedGender.value = "Male",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GenderOption(
              label: "Female",
              icon: Icons.female,
              isSelected: controller.selectedGender.value == "Female",
              onTap: () => controller.selectedGender.value = "Female",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GenderOption(
              label: "Other",
              icon: Icons.transgender,
              isSelected: controller.selectedGender.value == "Other",
              onTap: () => controller.selectedGender.value = "Other",
            ),
          ),
        ],
      ),
    ],
  );
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}