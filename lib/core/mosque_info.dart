/// The mosque's real details, filling the spec's bracketed placeholders.
abstract final class MosqueInfo {
  static const name = 'Turkish Islamic Center Canada';
  static const nameSecondary = 'Pape Camii · Kanada Türk İslam Vakfı';
  static const street = '336 Pape Avenue';
  static const city = 'Toronto, ON';
  static const postalCode = 'M4M 2W7';
  static const addressLine = '$street, $city $postalCode';
  static const phone = '647 834 2000';
  static const phoneUri = 'tel:+16478342000';
  static const email = 'info@papecami.com';
  static const website = 'papemosque.ca';
  static const websiteUri = 'https://papemosque.ca';
  static const mapsUri =
      'https://www.google.com/maps/search/?api=1&query=336+Pape+Avenue,+Toronto';

  /// The app's App Store page, added to shared events once the app is
  /// released. Empty until then, and nothing is shown for it.
  static const appStoreUrl = '';
}
