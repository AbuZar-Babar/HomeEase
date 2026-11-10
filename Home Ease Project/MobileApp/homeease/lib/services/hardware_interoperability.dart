import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper service for native mobile hardware integrations:
/// - Phone dialer (url_launcher)
/// - Camera & Gallery image picking (image_picker)
/// - Hybrid local-first Supabase Storage uploads with offline resilience
class HardwareInteroperability {
  /// Strips formatting characters from phone string, keeping digits and leading '+'
  static String cleanPhoneNumber(String rawPhone) {
    final trimmed = rawPhone.trim();
    if (trimmed.isEmpty) return '';
    final hasLeadingPlus = trimmed.startsWith('+');
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return hasLeadingPlus ? '+$digitsOnly' : digitsOnly;
  }

  /// Launches the native phone dialer with the cleaned phone number.
  /// Supports [customLauncher] for dependency injection and deterministic unit testing.
  static Future<bool> dialPhone(
    String rawPhone, {
    Future<bool> Function(Uri uri)? customLauncher,
  }) async {
    final clean = cleanPhoneNumber(rawPhone);
    if (clean.isEmpty) {
      debugPrint('dialPhone called with empty phone number');
      return false;
    }

    final uri = Uri.parse('tel:$clean');

    if (customLauncher != null) {
      return customLauncher(uri);
    }

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        debugPrint('Cannot launch dialer URL: $uri');
      }
    } catch (e) {
      debugPrint('HardwareInteroperability.dialPhone error: $e');
    }
    return false;
  }

  /// Selects an image using native camera or gallery.
  /// Returns the local file path, or null if cancelled.
  static Future<String?> pickImage({
    required ImageSource source,
    ImagePicker? customPicker,
  }) async {
    try {
      final picker = customPicker ?? ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      return file?.path;
    } catch (e) {
      debugPrint('HardwareInteroperability.pickImage error: $e');
      return null;
    }
  }

  /// Asynchronously uploads a local photo to a Supabase Storage bucket.
  /// Returns the uploaded path or public URL on success, or falls back to
  /// returning the local [filePath] when offline or unconfigured.
  static Future<String> uploadPhotoToStorage({
    required String filePath,
    required String bucket,
    SupabaseClient? customClient,
  }) async {
    SupabaseClient? client = customClient;
    if (client == null) {
      try {
        client = Supabase.instance.client;
      } catch (_) {
        client = null;
      }
    }

    if (client == null) {
      debugPrint('Supabase client unavailable. Retaining local file path.');
      return filePath;
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Local file does not exist at $filePath');
        return filePath;
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final storagePath = '$bucket/$fileName';

      final bytes = await file.readAsBytes();
      await client.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = client.storage.from(bucket).getPublicUrl(fileName);
      debugPrint('Uploaded to Supabase Storage: $publicUrl');
      return publicUrl.isNotEmpty ? publicUrl : storagePath;
    } catch (e) {
      debugPrint('HardwareInteroperability.uploadPhotoToStorage error: $e. Using local path.');
      return filePath;
    }
  }
}
