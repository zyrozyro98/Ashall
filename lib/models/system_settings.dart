class AppSystemSettings {
  final String currency;
  final String currencySymbol;
  final String country;
  final String region;
  final double defaultDeliveryFee;
  final double minOrderTotal;
  final bool maintenanceMode;
  final String contactPhone;
  final String supportEmail;
  final String aboutApp;
  final String termsOfService;

  final int orderConfirmationTimeoutMinutes;

  AppSystemSettings({
    this.currency = "الدرهم الإماراتي",
    this.currencySymbol = "AED",
    this.country = "الإمارات العربية المتحدة",
    this.region = "دبي",
    this.defaultDeliveryFee = 15.0,
    this.minOrderTotal = 30.0,
    this.maintenanceMode = false,
    this.contactPhone = "+971XXXXXXXXX",
    this.supportEmail = "support@ashall.com",
    this.aboutApp = "أشال هو منصة التوصيل الأسرع والأذكى في المنطقة.",
    this.termsOfService = "شروط وأحكام استخدام منصة أشال...",
    this.orderConfirmationTimeoutMinutes = 10,
  });

  AppSystemSettings copyWith({
    String? currency,
    String? currencySymbol,
    String? country,
    String? region,
    double? defaultDeliveryFee,
    double? minOrderTotal,
    bool? maintenanceMode,
    String? contactPhone,
    String? supportEmail,
    String? aboutApp,
    String? termsOfService,
    int? orderConfirmationTimeoutMinutes,
  }) {
    return AppSystemSettings(
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      country: country ?? this.country,
      region: region ?? this.region,
      defaultDeliveryFee: defaultDeliveryFee ?? this.defaultDeliveryFee,
      minOrderTotal: minOrderTotal ?? this.minOrderTotal,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      contactPhone: contactPhone ?? this.contactPhone,
      supportEmail: supportEmail ?? this.supportEmail,
      aboutApp: aboutApp ?? this.aboutApp,
      termsOfService: termsOfService ?? this.termsOfService,
      orderConfirmationTimeoutMinutes: orderConfirmationTimeoutMinutes ?? this.orderConfirmationTimeoutMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currency': currency,
      'currencySymbol': currencySymbol,
      'country': country,
      'region': region,
      'defaultDeliveryFee': defaultDeliveryFee,
      'minOrderTotal': minOrderTotal,
      'maintenanceMode': maintenanceMode,
      'contactPhone': contactPhone,
      'supportEmail': supportEmail,
      'aboutApp': aboutApp,
      'termsOfService': termsOfService,
      'orderConfirmationTimeoutMinutes': orderConfirmationTimeoutMinutes,
    };
  }

  factory AppSystemSettings.fromMap(Map<String, dynamic> map) {
    return AppSystemSettings(
      currency: map['currency'] ?? "الدرهم الإماراتي",
      currencySymbol: map['currencySymbol'] ?? "AED",
      country: map['country'] ?? "الإمارات العربية المتحدة",
      region: map['region'] ?? "دبي",
      defaultDeliveryFee: (map['defaultDeliveryFee'] ?? 15.0).toDouble(),
      minOrderTotal: (map['minOrderTotal'] ?? 30.0).toDouble(),
      maintenanceMode: map['maintenanceMode'] ?? false,
      contactPhone: map['contactPhone'] ?? "+971XXXXXXXXX",
      supportEmail: map['supportEmail'] ?? "support@ashall.com",
      aboutApp: map['aboutApp'] ?? "أشال هو منصة التوصيل الأسرع والأذكى في المنطقة.",
      termsOfService: map['termsOfService'] ?? "شروط وأحكام استخدام منصة أشال...",
      orderConfirmationTimeoutMinutes: map['orderConfirmationTimeoutMinutes'] ?? 10,
    );
  }
}

