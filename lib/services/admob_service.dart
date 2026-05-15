import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdMobService {
  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  bool _pendingInterstitialShow = false;

  static String get _bannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-4314901150154701/3836007102';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    return '';
  }

  static String get _interstitialAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-4314901150154701/2384314317';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return '';
  }

  Future<void> init() async {
    await MobileAds.instance.initialize();
  }

  // Test banner id
  BannerAd createBanner() {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
  }

  // Test interstitial id
  void loadInterstitial() {
    if (_loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
          if (_pendingInterstitialShow) {
            _pendingInterstitialShow = false;
            showInterstitialIfReady();
          }
        },
        onAdFailedToLoad: (_) {
          _loadingInterstitial = false;
          _interstitial = null;
          _pendingInterstitialShow = false;
        },
      ),
    );
  }

  void showInterstitialIfReady() {
    final ad = _interstitial;
    if (ad == null) {
      _pendingInterstitialShow = true;
      loadInterstitial();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
      },
    );

    ad.show();
  }

  void dispose() {
    _interstitial?.dispose();
  }
}
