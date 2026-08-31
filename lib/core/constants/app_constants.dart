/// App-wide constants matching backend enums
class AppConstants {
  AppConstants._();

  static const String appName = 'Woosh';
  static const String tagline = 'Be Safe, Be Fearless';

  /// User roles (must match backend UserRole enum)
  static const String rolePassenger = 'passenger';
  static const String roleRider = 'rider';

  /// Gender options (must match backend Gender enum)
  static const String genderMale = 'male';
  static const String genderFemale = 'female';
  static const String genderOther = 'other';

  /// Max emergency contacts
  static const int maxEmergencyContacts = 3;
}
