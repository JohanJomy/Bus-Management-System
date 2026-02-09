import 'package:flutter/material.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _busNumberController = TextEditingController();

  void _handleLogin() {
    // In a real app, validate bus number here
    Navigator.pushReplacementNamed(context, '/driver');
  }

  @override
  Widget build(BuildContext context) {
    // Colors from the template
    const bgColor = Color(0xFF0A1128); // navy-deep
    const iconBgColor = Color(0xFF152243); // navy-light
    const textMuted = Color(0xFF8E94A5); // muted-gray

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: textMuted),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Bus Icon Container
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(24), // rounded-3xl
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      
                      const SizedBox(height: 48),

                      // Title & Subtitle
                      const Text(
                        "Driver Login",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w300, // font-light
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Enter assigned bus number",
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Input Field
                      SizedBox(
                        width: 280,
                        child: TextField(
                          controller: _busNumberController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 60, // text-6xl
                            fontWeight: FontWeight.w300,
                            letterSpacing: -1.5, // tracking-tighter
                          ),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "000",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.1),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          textInputAction: TextInputAction.go,
                          onSubmitted: (_) => _handleLogin(),
                        ),
                      ),

                      const SizedBox(height: 40), // pt-4 roughly

                      // Forward Button
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _handleLogin,
                            child: const SizedBox(
                              width: 80,
                              height: 80,
                              child: Icon(
                                Icons.arrow_forward,
                                color: bgColor, // navy-deep
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 48, top: 24),
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  "HELP & SUPPORT",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5, // tracking-[0.2em]
                  ),
                ),
              ),
            ),

            // Home Indicator (Visual only, system handles this usually, but following design)
            Container(
              width: 128,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _busNumberController.dispose();
    super.dispose();
  }
}
