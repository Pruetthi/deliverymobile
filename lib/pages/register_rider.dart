import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterRiderPage extends StatefulWidget {
  const RegisterRiderPage({super.key});

  @override
  State<RegisterRiderPage> createState() => _RegisterRiderPageState();
}

class _RegisterRiderPageState extends State<RegisterRiderPage> {
  var phoneCtl = TextEditingController();
  var nameCtl = TextEditingController();
  var passwordCtl = TextEditingController();
  var profilePictureCtl = TextEditingController();
  var vehicleNumberCtl = TextEditingController();
  var vehiclePictureCtl = TextEditingController();
  var db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EB),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 11, 4, 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.delivery_dining,
                          size: 60,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // const Text(
                //   'Delivery',
                //   style: TextStyle(
                //     fontSize: 24,
                //     fontWeight: FontWeight.bold,
                //     color: Color(0xFFFF6B35),
                //   ),
                // ),
                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4B942),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Register To Rider',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C1810),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      _buildInputField('Phone', phoneCtl, TextInputType.phone),
                      const SizedBox(height: 16),
                      _buildInputField(
                        'Password',
                        passwordCtl,
                        TextInputType.text,
                        isPassword: true,
                      ),
                      const SizedBox(height: 16),

                      _buildInputField('Name', nameCtl, TextInputType.name),
                      const SizedBox(height: 16),

                      _buildInputField(
                        'Picture Profile',
                        profilePictureCtl,
                        TextInputType.url,
                      ),
                      const SizedBox(height: 16),

                      _buildInputField(
                        'Picture Vehicle',
                        vehiclePictureCtl,
                        TextInputType.url,
                      ),
                      const SizedBox(height: 16),

                      _buildInputField(
                        'Vehicle registration',
                        vehicleNumberCtl,
                        TextInputType.text,
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC3545),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: addData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    TextInputType keyboardType, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1EB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  void addData() async {
    if (nameCtl.text.isEmpty ||
        phoneCtl.text.isEmpty ||
        passwordCtl.text.isEmpty ||
        profilePictureCtl.text.isEmpty ||
        vehicleNumberCtl.text.isEmpty ||
        vehiclePictureCtl.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      var existingUser = await db
          .collection('rider')
          .where('phone', isEqualTo: phoneCtl.text)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        Get.snackbar(
          'Error',
          'This phone number is already registered',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      var docRef = db.collection('rider').doc();
      var data = {
        'rid': docRef.id,
        'name': nameCtl.text,
        'phone': phoneCtl.text,
        'password': passwordCtl.text,
        'profile_picture': profilePictureCtl.text,
        'vehicle_number': vehicleNumberCtl.text,
        'vehicle_picture': vehiclePictureCtl.text,
        'status': 'rider',
        'createAt': DateTime.now(),
      };

      await docRef.set(data);

      log('Rider registered successfully: ${nameCtl.text}');

      Get.snackbar(
        'Success',
        'Rider registration successful!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.off(() => const LoginPage());
    } catch (e) {
      log('Registration error: $e');
      Get.snackbar(
        'Error',
        'Registration failed. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    phoneCtl.dispose();
    nameCtl.dispose();
    passwordCtl.dispose();
    profilePictureCtl.dispose();
    vehicleNumberCtl.dispose();
    vehiclePictureCtl.dispose();
    super.dispose();
  }
}
