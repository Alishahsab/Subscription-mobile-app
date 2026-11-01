import 'package:url_launcher/url_launcher.dart';

Future<void> openWhatsApp(String number) {
  return launchUrl(Uri.parse('https://wa.me/92${number.substring(1)}'), mode: LaunchMode.externalApplication);
}
