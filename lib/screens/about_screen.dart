import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'kissswanyzzz@gmail.com',
      query: 'subject=Qcoder%20App%20-%20Contact',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Icon and Name
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFBB86FC), Color(0xFF03DAC6)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.qr_code_2, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.appTitle, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFBB86FC))),
                  const SizedBox(height: 8),
                  Text('${l10n.version} 1.0.0', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // About Section
            _buildSection(l10n.aboutApp, l10n.aboutDescription),

            const Divider(height: 40),

            // Features
            _buildSection(l10n.mainFeatures, l10n.featuresDescription),

            const Divider(height: 40),

            // Contact Section
            _buildSection(l10n.contactUs, l10n.contactDescription),
            
            const SizedBox(height: 16),
            
            InkWell(
              onTap: _launchEmail,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF03DAC6)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.email, color: Color(0xFF03DAC6)),
                    SizedBox(width: 16),
                    Expanded(child: Text('kissswanyzzz@gmail.com', style: TextStyle(color: Color(0xFF03DAC6), fontSize: 16))),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                  ],
                ),
              ),
            ),

            const Divider(height: 40),

            // Copyright
            _buildSection(l10n.copyright, l10n.copyrightText),

            const SizedBox(height: 24),

            // Links to legal pages
            _buildLegalLink(context, l10n.termsOfService, l10n.termsDescription, () => Navigator.push(context, MaterialPageRoute(builder: (_) => TermsScreen(l10n: l10n)))),

            const SizedBox(height: 12),

            _buildLegalLink(context, l10n.privacyPolicy, l10n.privacyDescription, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyScreen(l10n: l10n)))),

            const SizedBox(height: 40),

            // Footer
            Center(child: Text(l10n.madeWithLove, style: const TextStyle(color: Colors.grey, fontSize: 14))),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFBB86FC))),
        const SizedBox(height: 12),
        Text(content, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white70)),
      ],
    );
  }

  Widget _buildLegalLink(BuildContext context, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.description, color: Color(0xFFBB86FC)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  final AppLocalizations l10n;
  
  const TermsScreen({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    // Terms content (you can add more l10n strings for these if needed)
    final isArabic = l10n.arabic == 'العربية';
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.termsOfService)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(isArabic ? '1. قبول الشروط' : '1. Acceptance of Terms', 
              isArabic ? 'باستخدامك لتطبيق Qcoder، فإنك توافق على جميع الشروط والأحكام الموضحة هنا.' : 'By using Qcoder, you agree to all terms and conditions outlined here.'),
            _buildSection(isArabic ? '2. الاستخدام المسموح' : '2. Permitted Use', 
              isArabic ? 'التطبيق مخصص للاستخدام الشخصي والتجاري المشروع.' : 'The app is for personal and legitimate commercial use.'),
            _buildSection(isArabic ? '3. مسؤولية المستخدم' : '3. User Responsibility', 
              isArabic ? 'أنت المسؤول الوحيد عن أي محتوى تقوم بإنشائه أو مشاركته.' : 'You are solely responsible for any content you create or share.'),
            _buildSection(isArabic ? '4. الخصوصية' : '4. Privacy', 
              isArabic ? 'نحن نحترم خصوصيتك تماماً. التطبيق لا يقوم بجمع أو تخزين أي بيانات شخصية.' : 'We fully respect your privacy. The app does not collect or store any personal data.'),
            _buildSection(isArabic ? '5. إخلاء المسؤولية' : '5. Disclaimer', 
              isArabic ? 'التطبيق يُقدّم "كما هو" دون أي ضمانات.' : 'The app is provided "as is" without any warranties.'),
            _buildSection(isArabic ? '6. التعديلات' : '6. Modifications', 
              isArabic ? 'نحتفظ بالحق في تعديل هذه الشروط في أي وقت.' : 'We reserve the right to modify these terms at any time.'),
            _buildSection(isArabic ? '7. التواصل' : '7. Contact', 
              isArabic ? 'للاستفسارات: kissswanyzzz@gmail.com' : 'For inquiries: kissswanyzzz@gmail.com'),
            const SizedBox(height: 24),
            Center(child: Text('${isArabic ? 'آخر تحديث' : 'Last updated'}: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const TextStyle(color: Colors.grey, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFBB86FC))),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white70)),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  final AppLocalizations l10n;
  
  const PrivacyScreen({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isArabic = l10n.arabic == 'العربية';
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(isArabic ? 'التزامنا بحماية خصوصيتك' : 'Our Commitment to Your Privacy', 
              isArabic ? 'في Qcoder، خصوصيتك هي أولويتنا.' : 'At Qcoder, your privacy is our priority.'),
            _buildSection(isArabic ? '1. البيانات التي نجمعها' : '1. Data We Collect', 
              isArabic ? '✅ لا نجمع أي بيانات شخصية على الإطلاق' : '✅ We do not collect any personal data whatsoever'),
            _buildSection(isArabic ? '2. الأذونات المطلوبة' : '2. Required Permissions', 
              isArabic ? '📷 الكاميرا: لمسح رموز QR\n💾 التخزين: لحفظ الرموز\n🌐 الإنترنت: للإعلانات' : '📷 Camera: To scan QR codes\n💾 Storage: To save codes\n🌐 Internet: For ads'),
            _buildSection(isArabic ? '3. الإعلانات' : '3. Advertisements', 
              isArabic ? 'نستخدم Google AdMob لعرض إعلانات.' : 'We use Google AdMob to display ads.'),
            _buildSection(isArabic ? '4. المشاركة والحفظ' : '4. Sharing and Saving', 
              isArabic ? 'المحتوى ينتقل مباشرةً إلى التطبيق الذي تختاره.' : 'Content goes directly to the app you choose.'),
            _buildSection(isArabic ? '5. الأمان' : '5. Security', 
              isArabic ? 'نتخذ جميع الإجراءات المعقولة لحماية التطبيق.' : 'We take all reasonable measures to protect the app.'),
            _buildSection(isArabic ? '6. حقوقك' : '6. Your Rights', 
              isArabic ? 'بما أننا لا نجمع بيانات، لا توجد بيانات لحذفها.' : 'Since we collect no data, there is no data to delete.'),
            _buildSection(isArabic ? '7. التحديثات' : '7. Updates', 
              isArabic ? 'قد نقوم بتحديث سياسة الخصوصية من حين لآخر.' : 'We may update this privacy policy from time to time.'),
            _buildSection(isArabic ? '8. تواصل معنا' : '8. Contact Us', 
              isArabic ? 'للاستفسارات: kissswanyzzz@gmail.com' : 'For inquiries: kissswanyzzz@gmail.com'),
            const SizedBox(height: 24),
            Center(child: Text('${isArabic ? 'آخر تحديث' : 'Last updated'}: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const TextStyle(color: Colors.grey, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF03DAC6))),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white70)),
        ],
      ),
    );
  }
}
