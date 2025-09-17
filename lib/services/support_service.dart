import 'package:url_launcher/url_launcher.dart';

class SupportService {
  static const String supportPhoneNumber = '+996559868878';
  
  static SupportService? _instance;
  static SupportService get instance => _instance ??= SupportService._();
  SupportService._();

  Future<bool> callSupport() async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: supportPhoneNumber);
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> canCallSupport() async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: supportPhoneNumber);
      return await canLaunchUrl(phoneUri);
    } catch (e) {
      return false;
    }
  }

  String get supportPhone => supportPhoneNumber;
}
