import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  var phoneCtl = TextEditingController();
  var nameCtl = TextEditingController();
  var passwordCtl = TextEditingController();
  var profilePictureCtl = TextEditingController();
  var addressCtl = TextEditingController();
  var altAddressCtl = TextEditingController();

  var db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: Center(
        child: SingleChildScrollView(
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

              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Register",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildTextField("Name", nameCtl),
                    _buildTextField(
                      "Phone",
                      phoneCtl,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField("Password", passwordCtl, obscureText: true),
                    _buildTextField("Picture Profile", profilePictureCtl),
                    _buildTextField("Address", addressCtl),
                    _buildTextField("Alternative Address", altAddressCtl),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(120, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Get.back();
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            minimumSize: const Size(120, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: addData,
                          child: const Text(
                            "Confirm",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctl, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctl,
        obscureText: obscureText,
        keyboardType: keyboardType,

        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void addData() async {
    var docRef = db.collection('user').doc();
    var data = {
      'uid': docRef.id,
      'name': nameCtl.text,
      'phone': phoneCtl.text,
      'password': passwordCtl.text,
      'profile_picture': profilePictureCtl.text,
      'address': addressCtl.text,
      'alt_address': altAddressCtl.text,
      'status': 'user',
      'createAt': DateTime.timestamp(),
    };
    await docRef.set(data);
    Get.to(() => const LoginPage());
  }
}
