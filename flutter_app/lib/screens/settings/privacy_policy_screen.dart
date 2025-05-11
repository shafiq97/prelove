import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
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
            _buildSectionTitle('1. Introduction'),
            _buildSectionContent(
              'Preloved Closet ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application ("App"). Please read this Privacy Policy carefully. By accessing or using the App, you agree to the collection and use of information in accordance with this policy.',
            ),
            _buildSectionTitle('2. Information We Collect'),
            _buildSectionContent(
              'We may collect several types of information from and about users of our App, including:\n\n'
              '• Personal Information: Name, email address, postal address, phone number, payment information, and other identifiers that you voluntarily provide when creating an account or listing items.\n\n'
              '• Profile Information: Photos, item preferences, style preferences, and other information you choose to include in your profile.\n\n'
              '• Transaction Information: Details about purchases, sales, returns, and other transaction-related data.\n\n'
              '• Usage Data: Information about how you use the App, including pages visited, time spent, and actions taken.\n\n'
              '• Device Information: Device type, operating system, unique device identifiers, IP address, and mobile network information.',
            ),
            _buildSectionTitle('3. How We Use Your Information'),
            _buildSectionContent(
              'We use information that we collect about you or that you provide to us:\n\n'
              '• To provide, maintain, and improve our App\n'
              '• To process transactions and send transaction notifications\n'
              '• To create and maintain your account\n'
              '• To provide customer service\n'
              '• To personalize your experience\n'
              '• To communicate with you about products, services, and events\n'
              '• To monitor and analyze usage and trends\n'
              '• To detect, prevent, and address technical issues\n'
              '• To protect the rights, property, or safety of Preloved Closet, our users, or others',
            ),
            _buildSectionTitle('4. Information Sharing and Disclosure'),
            _buildSectionContent(
              'We may share your personal information in the following situations:\n\n'
              '• With other users as necessary to facilitate transactions (e.g., sharing shipping address with a seller)\n'
              '• With service providers who perform services on our behalf\n'
              '• To comply with legal obligations\n'
              '• To protect and defend our rights and property\n'
              '• With business partners with your consent\n'
              '• In connection with a merger, sale, or acquisition',
            ),
            _buildSectionTitle('5. Your Choices'),
            _buildSectionContent(
              'You can control the information we collect and how we use it in several ways:\n\n'
              '• Account Information: You can review and change your personal information by logging into the App and visiting your account profile page.\n\n'
              '• Communications: You can opt-out of receiving promotional emails by following the unsubscribe instructions in each message.\n\n'
              '• Privacy Settings: You can adjust privacy settings in your account to control what information is visible to other users.\n\n'
              '• Location Data: You can disable location services in your device settings.',
            ),
            _buildSectionTitle('6. Data Security'),
            _buildSectionContent(
              'We have implemented appropriate technical and organizational measures to secure your personal information from accidental loss and unauthorized access, use, alteration, and disclosure. However, no method of transmission over the Internet or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your personal information, we cannot guarantee its absolute security.',
            ),
            _buildSectionTitle('7. Data Retention'),
            _buildSectionContent(
              'We will retain your personal information only for as long as reasonably necessary to fulfill the purposes for which it was collected, including to satisfy any legal, regulatory, tax, accounting, or reporting requirements. In some circumstances, we may anonymize your personal information so that it can no longer be associated with you, in which case we may use such information without further notice to you.',
            ),
            _buildSectionTitle('8. Children\'s Privacy'),
            _buildSectionContent(
              'Our App is not intended for children under 16 years of age. We do not knowingly collect personal information from children under 16. If we learn we have collected or received personal information from a child under 16 without verification of parental consent, we will delete that information.',
            ),
            _buildSectionTitle('9. International Data Transfers'),
            _buildSectionContent(
              'Your information may be transferred to and processed in countries other than the country in which you reside. These countries may have data protection laws that are different from the laws of your country. By using the App, you consent to the transfer of your information to countries outside your country of residence.',
            ),
            _buildSectionTitle('10. Changes to This Privacy Policy'),
            _buildSectionContent(
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.',
            ),
            _buildSectionTitle('11. Contact Us'),
            _buildSectionContent(
              'If you have questions or concerns about this Privacy Policy or our practices, please contact us at privacy@prelovedcloset.com.',
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
