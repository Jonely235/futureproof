/// iCloud Error Types
///
/// Provides detailed error classification for iCloud operations.
library;

import 'package:flutter/foundation.dart';
import '../models/app_error.dart';

/// Categories of iCloud errors
enum ICloudErrorType {
  /// Network connectivity issues
  network,

  /// User not signed into iCloud
  notSignedIn,

  /// iCloud container not available or misconfigured
  containerUnavailable,

  /// Data size exceeds iCloud limits
  quotaExceeded,

  /// Invalid file name or path
  invalidFileName,

  /// File not found
  fileNotFound,

  /// Unknown or uncategorized error
  unknown,
}

/// Detailed error information for iCloud operations
class ICloudError {
  final ICloudErrorType type;
  final String message;
  final String? technicalDetails;
  final bool isRetryable;

  const ICloudError({
    required this.type,
    required this.message,
    this.technicalDetails,
    this.isRetryable = true,
  });

  /// Create an error from a PlatformException
  factory ICloudError.fromPlatformException(Object exception) {
    if (exception is! Exception) {
      return const ICloudError(
        type: ICloudErrorType.unknown,
        message: 'An unexpected error occurred',
        technicalDetails: 'Non-exception thrown',
      );
    }

    // Try to extract error code and message from platform exception
    final message = exception.toString().toLowerCase();

    // Classify error based on message content
    if (message.contains('network') || message.contains('connection')) {
      return const ICloudError(
        type: ICloudErrorType.network,
        message: 'Network connection unavailable. Please check your internet connection.',
        isRetryable: true,
      );
    }

    if (message.contains('not signed in') || message.contains('no account')) {
      return const ICloudError(
        type: ICloudErrorType.notSignedIn,
        message: 'Please sign in to iCloud in your device settings.',
        isRetryable: false,
      );
    }

    if (message.contains('container') || message.contains('ubiquity')) {
      return const ICloudError(
        type: ICloudErrorType.containerUnavailable,
        message: 'iCloud is not configured. Please check your app settings.',
        technicalDetails: 'iCloud container may be missing from entitlements',
        isRetryable: false,
      );
    }

    if (message.contains('quota') || message.contains('exceed') || message.contains('size')) {
      return const ICloudError(
        type: ICloudErrorType.quotaExceeded,
        message: 'Data is too large for iCloud sync. Please reduce the number of transactions.',
        isRetryable: false,
      );
    }

    if (message.contains('not found') || message.contains('no such file')) {
      return const ICloudError(
        type: ICloudErrorType.fileNotFound,
        message: 'No backup data found in iCloud.',
        isRetryable: false,
      );
    }

    // Default fallback
    return ICloudError(
      type: ICloudErrorType.unknown,
      message: 'iCloud sync failed. Please try again.',
      technicalDetails: exception.toString(),
      isRetryable: true,
    );
  }

  /// User-friendly description of the error
  String get description {
    switch (type) {
      case ICloudErrorType.network:
        return 'Network Error';
      case ICloudErrorType.notSignedIn:
        return 'iCloud Not Signed In';
      case ICloudErrorType.containerUnavailable:
        return 'iCloud Unavailable';
      case ICloudErrorType.quotaExceeded:
        return 'Data Too Large';
      case ICloudErrorType.invalidFileName:
        return 'Invalid File Name';
      case ICloudErrorType.fileNotFound:
        return 'No Backup Found';
      case ICloudErrorType.unknown:
        return 'Sync Failed';
    }
  }

  @override
  String toString() => 'ICloudError($type: $message)';

  @override
  bool operator ==(Object other) =>
      other is ICloudError &&
      other.type == type &&
      other.message == message;

  @override
  int get hashCode => Object.hash(type, message);
}

/// Result wrapper for iCloud Drive operations with detailed error info
class ICloudResult<T> {
  final T? data;
  final ICloudError? error;

  const ICloudResult._({this.data, this.error});

  factory ICloudResult.success(T data) {
    return ICloudResult._(data: data);
  }

  factory ICloudResult.failure(ICloudError error) {
    return ICloudResult._(error: error);
  }

  factory ICloudResult.failureFromException(Object exception) {
    final iCloudError = ICloudError.fromPlatformException(exception);
    return ICloudResult._(error: iCloudError);
  }

  /// Create a failure from a simple string message (for backwards compatibility)
  factory ICloudResult.failureWithString(String message) {
    return ICloudResult._(
      error: ICloudError(
        type: ICloudErrorType.unknown,
        message: message,
      ),
    );
  }

  /// Legacy property for backwards compatibility - returns error message as string
  String? get errorString => error?.message;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  ICloudErrorType? get errorType => error?.type;

  /// Get the data, throws if operation failed
  T get dataOrThrow {
    if (isFailure) {
      throw AppError(
        type: AppErrorType.icloud,
        message: errorMessage ?? 'Unknown iCloud error',
      );
    }
    return data as T;
  }

  /// User-friendly error message
  String? get errorMessage => error?.message;

  /// Error description for UI display
  String? get errorDescription => error?.description;
}
