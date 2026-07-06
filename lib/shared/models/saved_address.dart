class SavedAddress {
  final String label; // "Home", "Work", "Other", etc.
  final String addressLine;
  final double latitude;
  final double longitude;

  const SavedAddress({
    required this.label,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      label: json['label'] as String,
      addressLine: json['addressLine'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'addressLine': addressLine,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
