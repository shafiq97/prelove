import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms & Conditions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last Updated: May 10, 2025',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('1. Acceptance of Terms'),
            _buildSectionContent(
              'By accessing or using the Preloved Closet application ("the App"), you agree to be bound by these Terms and Conditions. If you do not agree to all the terms and conditions, you must not use the App.',
            ),
            _buildSectionTitle('2. Account Registration'),
            _buildSectionContent(
              'To use certain features of the App, you must register for an account. You agree to provide accurate, current, and complete information during the registration process and to update such information to keep it accurate, current, and complete. You are responsible for safeguarding your password and for all activities that occur under your account.',
            ),
            _buildSectionTitle('3. User Conduct'),
            _buildSectionContent(
              'You agree not to:\n\n'
              '• Upload false, misleading, or inappropriate content\n'
              '• Impersonate any person or entity\n'
              '• Interfere with or disrupt the services or servers\n'
              '• Attempt to gain unauthorized access to any part of the App\n'
              '• Use the App for any illegal purpose\n'
              '• Post content that infringes intellectual property rights',
            ),
            _buildSectionTitle('4. Listing and Sales'),
            _buildSectionContent(
              'When listing items for sale, you agree to:\n\n'
              '• Provide accurate descriptions and images\n'
              '• List only items that you legally own and have the right to sell\n'
              '• Set fair and transparent prices\n'
              '• Honor transactions when items are sold\n'
              '• Ship items as described in a timely manner\n\n'
              'Preloved Closet is not responsible for the quality, safety, or legality of items sold through the App.',
            ),
            _buildSectionTitle('5. Payments and Fees'),
            _buildSectionContent(
              'Transactions are processed through our secure payment system. Preloved Closet may charge fees for listings, sales, or other services as outlined in our Fee Schedule, which may be updated from time to time. You are responsible for all applicable taxes related to your use of the App.',
            ),
            _buildSectionTitle('6. Returns and Refunds'),
            _buildSectionContent(
              'Our return and refund policy allows buyers to request a return within 7 days of receiving an item if it significantly differs from the description. Sellers are required to accept returns in such cases. Preloved Closet reserves the right to mediate disputes between buyers and sellers.',
            ),
            _buildSectionTitle('7. Intellectual Property'),
            _buildSectionContent(
              'All content on the App, including text, graphics, logos, and software, is the property of Preloved Closet or its content suppliers and is protected by copyright and other intellectual property laws. Users retain ownership of content they upload but grant Preloved Closet a non-exclusive license to use, display, and distribute such content.',
            ),
            _buildSectionTitle('8. Termination'),
            _buildSectionContent(
              'Preloved Closet reserves the right to terminate or suspend your account and access to the App at any time, without notice, for conduct that we believe violates these Terms and Conditions or is harmful to other users, us, or third parties, or for any other reason at our sole discretion.',
            ),
            _buildSectionTitle('9. Limitation of Liability'),
            _buildSectionContent(
              'To the maximum extent permitted by law, Preloved Closet shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including lost profits, arising out of or relating to your use of the App.',
            ),
            _buildSectionTitle('10. Changes to Terms'),
            _buildSectionContent(
              'Preloved Closet reserves the right to modify these Terms and Conditions at any time. We will provide notice of significant changes by posting an updated version on the App. Your continued use of the App after changes constitutes your acceptance of the revised Terms.',
            ),
            _buildSectionTitle('11. Governing Law'),
            _buildSectionContent(
              'These Terms and Conditions shall be governed by and construed in accordance with the laws of Malaysia, without regard to its conflict of law provisions.',
            ),
            _buildSectionTitle('12. Contact Us'),
            _buildSectionContent(
              'If you have any questions about these Terms and Conditions, please contact us at support@prelovedcloset.com',
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                '© ${DateTime.now().year} Preloved Closet. All rights reserved.',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
      ),
    );
  }
}
