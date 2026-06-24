import 'package:flutter/material.dart';

import '../service/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  int stepIndex = 0;
  String? resetSessionToken;

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> requestCode() async {
    if (emailController.text.trim().isEmpty) {
      _showError('Email wajib diisi');
      return;
    }

    setState(() => isLoading = true);
    try {
      final result = await ApiService.forgotPassword(emailController.text);
      if (!mounted) return;
      setState(() => stepIndex = 1);
      _showSuccess(
        result['message']?.toString() ??
            'Jika email terdaftar, kode reset sudah dikirim.',
      );
    } catch (e) {
      _showError(_cleanError(e));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> verifyCode() async {
    if (codeController.text.trim().length != 6) {
      _showError('Kode reset harus 6 digit');
      return;
    }

    setState(() => isLoading = true);
    try {
      final result = await ApiService.verifyResetCode(
        emailController.text,
        codeController.text,
      );
      if (!mounted) return;
      setState(() {
        resetSessionToken = result['resetSessionToken']?.toString();
        stepIndex = 2;
      });
      _showSuccess('Kode reset valid. Silakan masukkan password baru.');
    } catch (e) {
      _showError(_cleanError(e));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> submitNewPassword() async {
    if (passwordController.text.length < 8) {
      _showError('Password minimal 8 karakter');
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      _showError('Konfirmasi password tidak cocok');
      return;
    }
    if (resetSessionToken == null || resetSessionToken!.isEmpty) {
      _showError('Sesi reset password tidak valid');
      return;
    }

    setState(() => isLoading = true);
    try {
      await ApiService.resetPassword(
        emailController.text,
        resetSessionToken!,
        passwordController.text,
      );
      if (!mounted) return;
      _showSuccess('Password berhasil diperbarui. Silakan login kembali.');
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      _showError(_cleanError(e));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    AppFeedback.showError(context, message);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    AppFeedback.showSuccess(context, message);
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AuthBrandHeader(),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Reset Password',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _stepSubtitle(),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildStepIndicator(),
          const SizedBox(height: 20),
          if (stepIndex == 0) _buildEmailStep(),
          if (stepIndex == 1) _buildVerificationStep(),
          if (stepIndex == 2) _buildPasswordStep(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Kembali ke Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final active = index <= stepIndex;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppTheme.primary : AppTheme.border,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }),
    );
  }

  String _stepSubtitle() {
    if (stepIndex == 0) {
      return 'Masukkan email akun untuk meminta kode reset password.';
    }
    if (stepIndex == 1) {
      return 'Masukkan kode 6 digit yang dikirim ke email Anda.';
    }
    return 'Masukkan password baru untuk menyelesaikan reset password.';
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration('Email', Icons.alternate_email),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : requestCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Kirim Kode',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      children: [
        TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: _inputDecoration('Kode reset 6 digit', Icons.pin_outlined),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Verifikasi Kode',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: _inputDecoration('Password baru', Icons.lock_outline),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: confirmPasswordController,
          obscureText: true,
          decoration: _inputDecoration(
            'Konfirmasi password',
            Icons.lock_outline,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : submitNewPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Simpan Password Baru',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      labelText: hintText,
      counterText: '',
      prefixIcon: Icon(icon, color: AppTheme.primary),
    );
  }
}
