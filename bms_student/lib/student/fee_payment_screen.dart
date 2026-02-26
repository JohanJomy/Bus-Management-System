import 'package:flutter/material.dart';
import 'package:razorpay_web/razorpay_web.dart';
import 'package:bms_student/student/screens/payment_receipt_screen.dart';
import 'package:intl/intl.dart';

class FeePaymentScreen extends StatefulWidget {
  const FeePaymentScreen({super.key});

  @override
  State<FeePaymentScreen> createState() => _FeePaymentScreenState();
}

class _FeePaymentScreenState extends State<FeePaymentScreen> {
  late Razorpay _razorpay;
  double _amountDue = 4500.00;
  final List<Map<String, String>> _paymentHistory = [
    {'title': 'Quarter 2 Fees', 'date': 'Jul 12, 2023', 'amount': '₹4500.00'},
    {'title': 'Quarter 1 Fees', 'date': 'Apr 05, 2023', 'amount': '₹4500.00'},
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_amountDue <= 0.0) return;

    final paymentId = response.paymentId ?? 'N/A';
    final date = DateFormat('MMM dd, yyyy').format(DateTime.now());
    
    final paymentDetails = {
      'title': 'Quarter 3 Fees',
      'date': date,
      'amount': '₹4500.00',
      'paymentId': paymentId,
    };
    
    setState(() {
      _amountDue = 0.00;
      _paymentHistory.insert(0, paymentDetails);
    });
    
    // Navigate naturally after state update
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentReceiptScreen(paymentDetails: paymentDetails),
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Successful! Payment ID: $paymentId')),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  void _resetPayment() {
    setState(() {
      _amountDue = 4500.00;
      // Remove the latest entry if it matches the one we add on success
      if (_paymentHistory.isNotEmpty && _paymentHistory.first['title'] == 'Quarter 3 Fees') {
        _paymentHistory.removeAt(0);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Reset for Testing')),
    );
  }

  void _openRazorpay() {
    var options = {
      'key': 'rzp_test_SKJarDIhvjFJgi',
      'amount': (_amountDue * 100).toInt(),
      'name': 'Bus Management System',
      'description': 'Fee Payment',
      'prefill': {
        'contact': '8281631936',
        'email': 'johanjk.csb2327@example.com',
      },
      'external': {
        'wallets': ['paytm', 'googlepay', 'phonepe']
      },
    };

    try {
      _razorpay.open(options, context: context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.grey[400] : Colors.grey[500];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Fee Payment',
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), // Reset button for testing
            tooltip: 'Reset Payment',
            onPressed: _resetPayment,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.pushNamed(context, '/restricted'),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                // Amount Due Section
                Center(
                  child: Column(
                    children: [
                      Text(
                        'AMOUNT DUE',
                        style: TextStyle(
                          color: subColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            _amountDue.toStringAsFixed(2),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -2.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_amountDue > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Due by Jan 15, 2026',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'All Dues Paid',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Recent Payments
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT PAYMENTS',
                      style: TextStyle(
                        color: subColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'View History',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._paymentHistory.map((payment) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildHistoryItem(
                      context,
                      payment['title']!,
                      payment['date']!,
                      payment['amount']!,
                      payment,
                    ),
                  );
                }),

                const SizedBox(height: 120),
              ],
            ),

            // Bottom Pay Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0F172A) : Colors.white).withOpacity(0.9),
                  border: Border(
                    top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                  ),
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _amountDue > 0 ? _openRazorpay : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137FEC),
                      disabledBackgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: _amountDue > 0 ? 5 : 0,
                      shadowColor: const Color(0xFF137FEC).withOpacity(0.4),
                    ),
                    child: Text(
                      _amountDue > 0 ? 'Pay ₹${_amountDue.toStringAsFixed(2)} Now' : 'Paid',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToReceipt(Map<String, dynamic> payment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentReceiptScreen(paymentDetails: payment),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String title, String date, String amount, Map<String, dynamic> payment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _navigateToReceipt(payment),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            ],
          ),
          const Spacer(),
          Text(
            amount,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
