/// Base utilities for model serialization/deserialization.
/// Centralizes common model conversion logic to reduce redundancy.
///
/// This file provides:
/// - Enum/String conversion utilities for all models
/// - Safe DateTime parsing across multiple formats (DateTime, Timestamp, String)
/// - Reusable factory patterns for Firestore integration
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class for shared model operations across all data models.
/// Prevents code duplication and ensures consistent serialization behavior.
abstract class ModelUtils {
  /// Converts an enum value to its string representation.
  ///
  /// Example: TaskPriority.high -> "high"
  ///
  /// Parameters:
  /// - [enumValue]: The enum value to convert
  ///
  /// Returns: String representation of the enum value (last part after '.')
  static String enumToString(Object enumValue) {
    return enumValue.toString().split('.').last;
  }

  /// Converts a string back to the corresponding enum value.
  ///
  /// Safely handles missing or mismatched values by returning a sensible default.
  /// Uses first enum value as default if string doesn't match any enum case.
  ///
  /// Parameters:
  /// - [enumValues]: List of all possible enum values (e.g., TaskPriority.values)
  /// - [stringValue]: String to convert back to enum
  ///
  /// Returns: Matching enum value, or first enum (default) if no match found
  ///
  /// Example:
  /// ```dart
  /// final priority = ModelUtils.stringToEnum(TaskPriority.values, "high");
  /// ```
  static T stringToEnum<T>(List<T> enumValues, String stringValue) {
    try {
      return enumValues.firstWhere(
        (e) => enumToString(e as Object) == stringValue,
        orElse: () => enumValues.first,
      );
    } catch (e) {
      // Fallback: return first enum value if any error occurs
      return enumValues.first;
    }
  }

  /// Safely parses DateTime from multiple possible formats.
  ///
  /// Handles:
  /// - Firestore Timestamp objects (auto-converts to DateTime)
  /// - Native Dart DateTime objects (returns as-is)
  /// - ISO 8601 string format (parses with fallback)
  ///
  /// Parameters:
  /// - [value]: The date value in any supported format
  /// - [fallback]: DateTime to use if parsing fails (default: now)
  ///
  /// Returns: Parsed DateTime or fallback value if parsing fails
  ///
  /// Example:
  /// ```dart
  /// final date = ModelUtils.parseDateTime(firestoreTimestamp);
  /// ```
  static DateTime parseDateTime(dynamic value, {DateTime? fallback}) {
    // If value is Firestore Timestamp, convert to DateTime
    if (value is Timestamp) {
      return value.toDate();
    }

    // If already DateTime, return as-is
    if (value is DateTime) {
      return value;
    }

    // If string, attempt ISO 8601 parse
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }

    // If parsing fails or unsupported type, use fallback (default: now)
    return fallback ?? DateTime.now();
  }

  /// Safely converts Firestore Timestamp to DateTime with error handling.
  ///
  /// Used specifically for Firestore documents where Timestamp is guaranteed.
  /// Provides better error messages than generic parseDateTime.
  ///
  /// Parameters:
  /// - [timestamp]: The Firestore Timestamp object
  ///
  /// Returns: Converted DateTime
  static DateTime timestampToDateTime(Timestamp timestamp) {
    return timestamp.toDate();
  }

  /// Converts DateTime to Firestore-compatible Timestamp format.
  ///
  /// Always use this when storing DateTime values in Firestore.
  ///
  /// Parameters:
  /// - [dateTime]: The DateTime to convert
  ///
  /// Returns: Firestore Timestamp object
  static Timestamp dateTimeToTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}
