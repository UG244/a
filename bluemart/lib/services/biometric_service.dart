import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Memeriksa apakah sensor sidik jari / biometrik tersedia dan didukung oleh perangkat keras HP.
  Future<bool> canAuthenticate() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Mendapatkan daftar biometrik yang terdaftar pada smartphone (misal Fingerprint / Face ID).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return <BiometricType>[];
    }
  }

  /// Memeriksa apakah perangkat memiliki sensor sidik jari (Fingerprint) atau biometrik kuat lainnya.
  Future<bool> hasFingerprintSupport() async {
    final canAuth = await canAuthenticate();
    if (!canAuth) return false;
    try {
      final available = await getAvailableBiometrics();
      return available.contains(BiometricType.fingerprint) ||
          available.contains(BiometricType.strong) ||
          available.isNotEmpty ||
          await _auth.canCheckBiometrics;
    } catch (_) {
      return await canAuthenticate();
    }
  }

  /// Menjalankan autentikasi sidik jari langsung ke sensor perangkat keras smartphone.
  Future<bool> authenticate({
    required BuildContext context,
    String localizedReason = 'Sentuh sensor sidik jari Anda untuk memverifikasi',
  }) async {
    bool canCheck = false;
    bool isSupported = false;
    List<BiometricType> available = [];

    try {
      canCheck = await _auth.canCheckBiometrics;
      isSupported = await _auth.isDeviceSupported();
      available = await _auth.getAvailableBiometrics();
    } catch (e) {
      if (context.mounted) {
        final errStr = e.toString();
        if (errStr.contains('MissingPluginException') ||
            errStr.contains('No implementation found') ||
            errStr.contains('channel-error')) {
          _showErrorSnackBar(
            context,
            'PENTING: Plugin sidik jari baru ditambahkan. Harap STOP/TUTUP aplikasi lalu jalankan ulang (Full Re-build/flutter run) agar sensor aktif!',
          );
        } else {
          _showErrorSnackBar(
            context,
            'Gagal membaca status sensor sidik jari HP Anda: $e',
          );
        }
      }
      return false;
    }

    // Jika perangkat sama sekali tidak mendukung biometrik
    if (!canCheck && !isSupported && available.isEmpty) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'HP Anda belum mendaftarkan sidik jari. Silakan buka [Pengaturan HP -> Sandi & Keamanan -> Sidik Jari] untuk mendaftarkan jari Anda terlebih dahulu.',
        );
      }
      return false;
    }

    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false, // Diganti false agar kompatibel sempurna dengan MIUI / HyperOS Xiaomi
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      if (context.mounted) {
        String errorMessage = 'Verifikasi sidik jari dibatalkan atau gagal.';
        if (e.code == auth_error.notAvailable) {
          errorMessage = 'Sensor sidik jari sedang tidak tersedia atau dinonaktifkan sistem.';
        } else if (e.code == auth_error.notEnrolled || e.code == 'NotEnrolled') {
          errorMessage = 'Belum ada sidik jari yang terdaftar di HP ini. Buka Pengaturan HP -> Sandi & Keamanan -> Sidik Jari.';
        } else if (e.code == auth_error.lockedOut || e.code == auth_error.permanentlyLockedOut) {
          errorMessage = 'Sensor sidik jari terkunci sementara karena terlalu banyak percobaan gagal. Gunakan PIN/Sandi HP Anda.';
        } else if (e.code == auth_error.passcodeNotSet) {
          errorMessage = 'Anda harus mengatur kunci layar (PIN/Pola/Password) di Pengaturan HP Anda terlebih dahulu.';
        } else if (e.message?.contains('MissingPluginException') == true ||
                   e.message?.contains('No implementation found') == true) {
          errorMessage = 'Plugin sidik jari belum terpasang di APK. Harap STOP aplikasi dan jalan ulang (Full Rebuild/flutter run).';
        }
        _showErrorSnackBar(context, errorMessage);
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        if (e.toString().contains('MissingPluginException') ||
            e.toString().contains('No implementation found')) {
          _showErrorSnackBar(
            context,
            'PENTING: Plugin sidik jari baru ditambahkan. Harap STOP aplikasi dan jalankan ulang (Full Rebuild/flutter run).',
          );
        } else {
          _showErrorSnackBar(context, 'Terjadi kesalahan pada sensor sidik jari: $e');
        }
      }
      return false;
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.fingerprint, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
