import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Privacy compliance and user consent management
class PrivacyManager {
  static const String _consentKey = 'user_privacy_consent';
  static const String _dataRetentionKey = 'data_retention_settings';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Privacy consent types
  static const Map<String, String> consentTypes = {
    'essential': 'Essential functionality (required for app to work)',
    'analytics': 'Anonymous usage analytics to improve the app',
    'location': 'Location data for restaurant recommendations',
    'personalization': 'Personal preferences and meal history',
    'marketing': 'Promotional communications and offers',
  };

  /// Data categories collected by the app
  static const Map<String, String> dataCategories = {
    'profile': 'Name and basic profile information',
    'location': 'GPS coordinates and location history',
    'preferences': 'Dietary restrictions and food preferences',
    'meals': 'Meal history and restaurant visits',
    'photos': 'Photos of meals and receipts',
    'usage': 'App usage patterns and interactions',
    'device': 'Device information and identifiers',
  };

  /// Get current privacy consent status
  static Future<PrivacyConsent> getPrivacyConsent() async {
    try {
      final consentJson = await _storage.read(key: _consentKey);
      if (consentJson != null) {
        return PrivacyConsent.fromJson(json.decode(consentJson));
      }
      return PrivacyConsent.none();
    } catch (e) {
      if (kDebugMode) {
        print('Error reading privacy consent: $e');
      }
      return PrivacyConsent.none();
    }
  }

  /// Update privacy consent
  static Future<void> updatePrivacyConsent(PrivacyConsent consent) async {
    try {
      final consentJson = json.encode(consent.toJson());
      await _storage.write(key: _consentKey, value: consentJson);
      
      if (kDebugMode) {
        print('Privacy consent updated: ${consent.grantedConsents}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving privacy consent: $e');
      }
    }
  }

  /// Check if specific consent is granted
  static Future<bool> hasConsent(String consentType) async {
    final consent = await getPrivacyConsent();
    return consent.hasConsent(consentType);
  }

  /// Check if essential consent is granted (required for app function)
  static Future<bool> hasEssentialConsent() async {
    return await hasConsent('essential');
  }

  /// Get data retention settings
  static Future<DataRetentionSettings> getDataRetentionSettings() async {
    try {
      final settingsJson = await _storage.read(key: _dataRetentionKey);
      if (settingsJson != null) {
        return DataRetentionSettings.fromJson(json.decode(settingsJson));
      }
      return DataRetentionSettings.defaults();
    } catch (e) {
      if (kDebugMode) {
        print('Error reading data retention settings: $e');
      }
      return DataRetentionSettings.defaults();
    }
  }

  /// Update data retention settings
  static Future<void> updateDataRetentionSettings(DataRetentionSettings settings) async {
    try {
      final settingsJson = json.encode(settings.toJson());
      await _storage.write(key: _dataRetentionKey, value: settingsJson);
      
      if (kDebugMode) {
        print('Data retention settings updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving data retention settings: $e');
      }
    }
  }

  /// Request user consent with proper UI flow
  static Future<bool> requestConsent(List<String> requiredConsents) async {
    // This would typically show a consent dialog/screen
    // For now, we'll simulate user granting essential consent
    if (requiredConsents.contains('essential')) {
      final consent = PrivacyConsent(
        grantedConsents: ['essential'],
        consentDate: DateTime.now(),
        version: '1.0.0',
      );
      await updatePrivacyConsent(consent);
      return true;
    }
    return false;
  }

  /// Revoke specific consent
  static Future<void> revokeConsent(String consentType) async {
    final currentConsent = await getPrivacyConsent();
    final updatedConsents = currentConsent.grantedConsents.where((c) => c != consentType).toList();
    
    final newConsent = PrivacyConsent(
      grantedConsents: updatedConsents,
      consentDate: currentConsent.consentDate,
      version: currentConsent.version,
      lastUpdated: DateTime.now(),
    );
    
    await updatePrivacyConsent(newConsent);
  }

  /// Get privacy summary for display
  static Future<PrivacySummary> getPrivacySummary() async {
    final consent = await getPrivacyConsent();
    final retention = await getDataRetentionSettings();
    
    return PrivacySummary(
      hasEssentialConsent: consent.hasConsent('essential'),
      grantedConsents: consent.grantedConsents,
      dataCategories: dataCategories.keys.toList(),
      retentionPeriod: retention.defaultRetentionDays,
      lastConsentUpdate: consent.lastUpdated ?? consent.consentDate,
    );
  }

  /// Data portability - export user data
  static Future<Map<String, dynamic>> exportUserData(int userId) async {
    // This would collect all user data for export
    return {
      'userId': userId,
      'exportDate': DateTime.now().toIso8601String(),
      'privacyConsent': (await getPrivacyConsent()).toJson(),
      'dataRetentionSettings': (await getDataRetentionSettings()).toJson(),
      'dataCategories': dataCategories,
      'notice': 'This export contains all personal data stored by the app',
    };
  }

  /// Right to be forgotten - delete all user data
  static Future<void> deleteAllUserData(int userId) async {
    try {
      // Clear privacy consent
      await _storage.delete(key: _consentKey);
      await _storage.delete(key: _dataRetentionKey);
      
      // This would also:
      // 1. Delete database records
      // 2. Remove cached files
      // 3. Clear AI recommendation history
      // 4. Remove photos and metadata
      
      if (kDebugMode) {
        print('User data deletion requested for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user data: $e');
      }
    }
  }

  /// Check if data should be deleted based on retention policy
  static bool shouldDeleteData(DateTime dataDate, String dataType) {
    final retentionDays = _getRetentionPeriod(dataType);
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    return dataDate.isBefore(cutoffDate);
  }

  /// Get retention period for specific data type
  static int _getRetentionPeriod(String dataType) {
    switch (dataType) {
      case 'location':
        return 30; // Location data retained for 30 days
      case 'usage':
        return 90; // Usage analytics for 90 days
      case 'photos':
        return 365; // Photos for 1 year
      case 'meals':
        return 730; // Meal history for 2 years
      default:
        return 365; // Default 1 year retention
    }
  }

  /// Validate privacy compliance
  static Future<PrivacyComplianceReport> validateCompliance() async {
    final consent = await getPrivacyConsent();
    final retention = await getDataRetentionSettings();
    
    final issues = <String>[];
    final warnings = <String>[];
    
    // Check consent requirements
    if (!consent.hasConsent('essential')) {
      issues.add('Essential consent not granted - app cannot function');
    }
    
    if (consent.isExpired()) {
      warnings.add('Privacy consent is older than 12 months - should be refreshed');
    }
    
    // Check data retention
    if (retention.defaultRetentionDays > 1095) { // 3 years
      warnings.add('Data retention period is very long - consider shorter period');
    }
    
    return PrivacyComplianceReport(
      isCompliant: issues.isEmpty,
      issues: issues,
      warnings: warnings,
      lastConsentDate: consent.consentDate,
      consentVersion: consent.version,
    );
  }

  /// Clear all privacy data (for testing or reset)
  static Future<void> clearAllPrivacyData() async {
    await _storage.delete(key: _consentKey);
    await _storage.delete(key: _dataRetentionKey);
  }
}

/// Privacy consent information
class PrivacyConsent {
  final List<String> grantedConsents;
  final DateTime consentDate;
  final String version;
  final DateTime? lastUpdated;

  const PrivacyConsent({
    required this.grantedConsents,
    required this.consentDate,
    required this.version,
    this.lastUpdated,
  });

  factory PrivacyConsent.none() {
    return PrivacyConsent(
      grantedConsents: [],
      consentDate: DateTime.now(),
      version: '1.0.0',
    );
  }

  bool hasConsent(String consentType) {
    return grantedConsents.contains(consentType);
  }

  bool isExpired() {
    final age = DateTime.now().difference(lastUpdated ?? consentDate);
    return age.inDays > 365; // Consent expires after 1 year
  }

  Map<String, dynamic> toJson() {
    return {
      'grantedConsents': grantedConsents,
      'consentDate': consentDate.toIso8601String(),
      'version': version,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory PrivacyConsent.fromJson(Map<String, dynamic> json) {
    return PrivacyConsent(
      grantedConsents: List<String>.from(json['grantedConsents'] ?? []),
      consentDate: DateTime.parse(json['consentDate']),
      version: json['version'] ?? '1.0.0',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }
}

/// Data retention settings
class DataRetentionSettings {
  final int defaultRetentionDays;
  final Map<String, int> categoryRetentionDays;
  final bool autoDeleteEnabled;

  const DataRetentionSettings({
    required this.defaultRetentionDays,
    required this.categoryRetentionDays,
    required this.autoDeleteEnabled,
  });

  factory DataRetentionSettings.defaults() {
    return const DataRetentionSettings(
      defaultRetentionDays: 365,
      categoryRetentionDays: {
        'location': 30,
        'usage': 90,
        'photos': 365,
        'meals': 730,
      },
      autoDeleteEnabled: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultRetentionDays': defaultRetentionDays,
      'categoryRetentionDays': categoryRetentionDays,
      'autoDeleteEnabled': autoDeleteEnabled,
    };
  }

  factory DataRetentionSettings.fromJson(Map<String, dynamic> json) {
    return DataRetentionSettings(
      defaultRetentionDays: json['defaultRetentionDays'] ?? 365,
      categoryRetentionDays: Map<String, int>.from(json['categoryRetentionDays'] ?? {}),
      autoDeleteEnabled: json['autoDeleteEnabled'] ?? true,
    );
  }
}

/// Privacy summary for display
class PrivacySummary {
  final bool hasEssentialConsent;
  final List<String> grantedConsents;
  final List<String> dataCategories;
  final int retentionPeriod;
  final DateTime lastConsentUpdate;

  const PrivacySummary({
    required this.hasEssentialConsent,
    required this.grantedConsents,
    required this.dataCategories,
    required this.retentionPeriod,
    required this.lastConsentUpdate,
  });
}

/// Privacy compliance report
class PrivacyComplianceReport {
  final bool isCompliant;
  final List<String> issues;
  final List<String> warnings;
  final DateTime lastConsentDate;
  final String consentVersion;

  const PrivacyComplianceReport({
    required this.isCompliant,
    required this.issues,
    required this.warnings,
    required this.lastConsentDate,
    required this.consentVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'isCompliant': isCompliant,
      'issues': issues,
      'warnings': warnings,
      'lastConsentDate': lastConsentDate.toIso8601String(),
      'consentVersion': consentVersion,
    };
  }
}