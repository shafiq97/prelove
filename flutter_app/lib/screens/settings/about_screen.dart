import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme_config.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Preloved Closet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checkroom,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // App Name and Version
            const Text(
              'Preloved Closet',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // App Description
            const Text(
              'Your sustainable fashion marketplace',
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 24),

            // Mission Statement
            const Text(
              'Our Mission',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Preloved Closet is dedicated to extending the lifecycle of clothing and reducing fashion waste by creating a user-friendly platform for buying and selling preloved clothing. We believe that sustainable fashion should be accessible to everyone.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Features
            const Text(
              'Key Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
                Icons.shopping_bag, 'Buy & Sell Preloved Clothing'),
            _buildFeatureItem(Icons.checkroom, 'Virtual Closet Management'),
            _buildFeatureItem(
                Icons.calendar_month, 'Outfit Planning & Scheduling'),
            _buildFeatureItem(
                Icons.volunteer_activism, 'Donation Center Locator'),
            _buildFeatureItem(Icons.eco, 'Sustainability Impact Tracker'),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // Developer Info
            const Text(
              'Developed By',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Preloved Closet Team',
              style: TextStyle(
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Final Year Project - 2025',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Contact Information
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactButton(
              context,
              Icons.email,
              'support@prelovedcloset.com',
              'mailto:support@prelovedcloset.com',
            ),
            _buildContactButton(
              context,
              Icons.language,
              'www.prelovedcloset.com',
              'https://www.prelovedcloset.com',
            ),

            const SizedBox(height: 32),

            // Social Media Links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                    Icons.facebook, Colors.blue, 'https://facebook.com'),
                const SizedBox(width: 16),
                _buildSocialButton(
                    Icons.camera_alt, Colors.pink, 'https://instagram.com'),
                const SizedBox(width: 16),
                _buildSocialButton(
                    Icons.chat_bubble, Colors.lightBlue, 'https://twitter.com'),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // Acknowledgements
            const Text(
              'Acknowledgements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'We would like to thank our mentors, beta testers, and everyone who supported the development of this application.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Copyright
            Text(
              '© ${DateTime.now().year} Preloved Closet. All rights reserved.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(
      BuildContext context, IconData icon, String text, String url) {
    return InkWell(
      onTap: () async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not launch $url')),
            );
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, String url) {
    return InkWell(
      onTap: () async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: CircleAvatar(
        radius: 24,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
