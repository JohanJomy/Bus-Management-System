import 'package:flutter/material.dart';
import 'profile_screen.dart';

class BusManagementApp extends StatelessWidget {
  const BusManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bus Management System',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (c) => const StudentLoginPage(),
        '/profile': (c) => const ProfileScreen(),
      },
    );
  }
}

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});

  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final idController = TextEditingController();
  final passController = TextEditingController();
  bool rememberMe = false;

  void login() {
    if (idController.text.isNotEmpty && passController.text.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/profile', arguments: {
        'id': idController.text,
        'name': 'Student ${idController.text}',
        'branch': 'Computer Science & Engineering',
        'college': 'Stitch Institute of Technology',
        'busNumber': '42B',
        'busStop': 'North Avenue, Stop #5',
        'feeStatus': 'Paid',
        'imageUrl': 'https://i.pravatar.cc/300?u=${idController.text}',
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter ID and Password')),
      );
    }
  }

  @override
  void dispose() {
    idController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: const Color(0xfff6f7f8),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 440 : 760),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Branding
                            Container(
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.directions_bus_filled,
                                        color: Colors.white, size: 48),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'BusTrack Student',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Access your bus routes and manage fees',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Login Card
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: idController,
                                      decoration: InputDecoration(
                                        labelText: 'Student ID',
                                        prefixIcon: const Icon(Icons.badge),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: passController,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: const Icon(Icons.lock),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: rememberMe,
                                              activeColor: primaryColor,
                                              onChanged: (v) => setState(() => rememberMe = v ?? false),
                                            ),
                                            const Text('Remember Me'),
                                          ],
                                        ),
                                        TextButton(onPressed: () {}, child: const Text('Forgot Password?')),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Sign In'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: const [
                                        Expanded(child: Divider()),
                                        Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('OR')),
                                        Expanded(child: Divider()),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.mail, color: Colors.blue),
                                        label: const Text('Continue with Google'),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                                        child: const Text('Log in with Enterprise ID'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Text("Don't have an account? "),
                                        Text('Register your ID', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            // Left: Branding
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.directions_bus_filled, color: Colors.white, size: 56),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text('BusTrack Student', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  const Text('Access your bus routes and manage fees', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right: Login card
                            Expanded(
                              child: Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(28.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(radius: 36, backgroundColor: primaryColor.withOpacity(0.12), child: const Icon(Icons.school, size: 36, color: primaryColor)),
                                      const SizedBox(height: 20),
                                      const Text('Student Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      TextField(controller: idController, decoration: InputDecoration(labelText: 'Student ID', prefixIcon: const Icon(Icons.badge), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                                      const SizedBox(height: 12),
                                      TextField(controller: passController, obscureText: true, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                                      const SizedBox(height: 12),
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Checkbox(value: rememberMe, activeColor: primaryColor, onChanged: (v) => setState(() => rememberMe = v ?? false)), const Text('Remember Me')]), TextButton(onPressed: () {}, child: const Text('Forgot Password?'))]),
                                      const SizedBox(height: 12),
                                      SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: login, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Sign In', style: TextStyle(fontSize: 16)))),
                                      const SizedBox(height: 16),
                                      Row(children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('OR')), Expanded(child: Divider())]),
                                      const SizedBox(height: 12),
                                      SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.mail, color: Colors.blue), label: const Text('Continue with Google'))),
                                      const SizedBox(height: 8),
                                      SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.black87), child: const Text('Log in with Enterprise ID'))),
                                      const SizedBox(height: 12),
                                      Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Text("Don't have an account? "), Text('Register your ID', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))]),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

