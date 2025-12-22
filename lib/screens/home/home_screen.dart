import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:async';
import 'dart:io';
import 'package:mobile_scanner/mobile_scanner.dart'; // For parsing shared images if needed

import '../about_screen.dart';
import 'tabs/scanner_tab.dart';
import 'tabs/generator_tab.dart';
import '../../utils/ui_utils.dart';

/// The Main Screen of the application.
/// 
/// Responsibilities:
/// 1. App Bar & Global Actions (Language, About)
/// 2. Tab Navigation (Scanner vs Generator)
/// 3. AdMob Banner Management
/// 4. Deep Linking / Sharing Intent listeners (Handle incoming text/images)
class HomeScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  
  const HomeScreen({super.key, required this.onLocaleChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Navigation State
  bool _isGenerateMode = false;
  bool _isScanningFull = false; // NEW: Track if camera is active
  
  // Sharing / Deep Linking State
  StreamSubscription? _intentDataStreamSubscription;
  String? _sharedText;
  
  // Ads
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _initSharing();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  // --- INITIALIZATION ---

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Ad failed: ${error.code}');
        },
      ),
    )..load();
  }

  /// Listen for data shared from other apps (Text or Images)
  void _initSharing() {
    // 1. Listen for new intents while app is running
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (mounted) _processSharedContent(value);
    }, onError: (err) {
      debugPrint("getMediaStream error: $err");
    });

    // 2. Handle intent that launched the app
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (mounted) _processSharedContent(value);
    });
  }

  void _processSharedContent(List<SharedMediaFile> sharedFiles) {
    if (sharedFiles.isEmpty) return;
    
    final file = sharedFiles.first;
    
    if (file.type == SharedMediaType.text) {
       // If Text/URL -> Open Generator Tab
       setState(() {
         _isGenerateMode = true; // Switch to Generate
         _sharedText = file.path; // Note: 'path' contains text for text type
       });
       // Use a global key or provider to pre-fill? 
       // For simplicity in V1 refactor, we pass down via constructor? 
       // GeneratorTab is stateful, so passing data requires a reload or controller access.
       // We'll leave it simple: user switches tab manually? No, we switched _isGenerateMode.
       // TODO: Ideally pass this to GeneratorTab.
    } else if (file.type == SharedMediaType.image) {
       // If Image -> Open Scanner Tab
       setState(() {
         _isGenerateMode = false; // Switch to Scan
       });
       // Trigger scan logic? Complex to pass down without State Management.
       // For V1, we just switch tabs. 
       // User can click "Gallery" inside ScannerTab.
       // OR: We could try to analyse immediately.
       showToast(context, 'Image received. Select "Gallery" to scan it.');
    }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // If Scanning Full Screen, hide AppBar and Tabs
    if (_isScanningFull) {
      return Scaffold(
        body: ScannerTab(
          initialData: _sharedText,
          onScanningChanged: (isScanning) => setState(() => _isScanningFull = isScanning),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: Column(
        children: [
          _buildTabSelector(l10n),
          Expanded(
            child: _isGenerateMode 
                ? const GeneratorTab() 
                : ScannerTab(
                    initialData: _sharedText,
                    onScanningChanged: (isScanning) => setState(() => _isScanningFull = isScanning),
                  ), 
          ),
          if (_isAdLoaded && _bannerAd != null)
            SizedBox(
              height: 50,
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Directionality(
        textDirection: TextDirection.ltr, // Force LTR to keep logo on left
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             ClipRRect(
               borderRadius: BorderRadius.circular(8),
               child: Image.asset(
                  'assets/icon.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
             ),
            const SizedBox(width: 12),
            Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      actions: [
        // Force LTR for actions too if user wants fixed positions
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.language),
                onPressed: () {
                  final currentLocale = Localizations.localeOf(context);
                  widget.onLocaleChange(
                    currentLocale.languageCode == 'en' ? const Locale('ar') : const Locale('en')
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: l10n.scanTab, 
              icon: Icons.qr_code_scanner, 
              isActive: !_isGenerateMode, 
              onTap: () => setState(() => _isGenerateMode = false)
            )
          ),
          Expanded(
            child: _buildTabButton(
              label: l10n.generateTab, 
              icon: Icons.qr_code, 
              isActive: _isGenerateMode, 
              onTap: () => setState(() => _isGenerateMode = true)
            )
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label, 
    required IconData icon, 
    required bool isActive, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive 
              ? const LinearGradient(colors: [Color(0xFF03DAC6), Color(0xFF00B8A9)]) 
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.black : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label, 
              style: TextStyle(
                color: isActive ? Colors.black : Colors.grey, 
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
      ),
    );
  }
}
