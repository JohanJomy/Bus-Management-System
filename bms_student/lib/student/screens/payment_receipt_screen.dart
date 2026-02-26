import 'package:flutter/material.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> paymentDetails;

  const PaymentReceiptScreen({super.key, required this.paymentDetails});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Successful',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction has been completed.',
              style: TextStyle(
                fontSize: 14,
                color: subColor,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                   Text(
                    'Total Amount Paid',
                    style: TextStyle(
                      fontSize: 14,
                      color: subColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    paymentDetails['amount'] ?? '₹0.00',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildDetailRow('Payment ID', paymentDetails['paymentId'] ?? 'N/A', textColor, subColor),
                  const SizedBox(height: 16),
                  _buildDetailRow('Date & Time', paymentDetails['date'] ?? 'N/A', textColor, subColor),
                  const SizedBox(height: 16),
                  _buildDetailRow('Payment For', paymentDetails['title'] ?? 'Fee Payment', textColor, subColor),
                  const SizedBox(height: 16),
                  _buildDetailRow('Status', 'Success', Colors.green, subColor),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor, Color? labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: labelColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
