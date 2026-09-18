import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/auth_service.dart';
import '../../../core/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onSuccess});
  final VoidCallback onSuccess;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;
  bool _loading = false;
  String? _error;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedDob;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();

    // Validate before touching loading state
    if (!_isSignIn && fullName.isEmpty) {
      setState(() => _error = 'Please enter your full name.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Please enter a valid email.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (!_isSignIn && _confirmPasswordController.text != password) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (!_isSignIn && _phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your phone number.');
      return;
    }
    if (!_isSignIn && _selectedDob == null) {
      setState(() => _error = 'Please select your date of birth.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final String? error;
    if (_isSignIn) {
      error = await AuthService.signInWithEmail(email, password);
    } else {
      error = await AuthService.signUpWithEmail(
        email,
        password,
        fullName,
        phone: _phoneController.text.trim(),
        dateOfBirth: _selectedDob!,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _error = error);
    } else {
      widget.onSuccess();
    }
  }

  void _toggle() {
    setState(() {
      _isSignIn = !_isSignIn;
      _error = null;
      _fullNameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _phoneController.clear();
      _selectedDob = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'MYT',
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.gold,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isSignIn ? 'Sign In' : 'Create Account',
            style: GoogleFonts.cormorantGaramond(
              color: AppColors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 28),
          if (!_isSignIn) ...[
            _buildField(
              controller: _fullNameController,
              label: 'Full Name',
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
          ],
          _buildField(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _passwordController,
            label: 'Password',
            obscure: true,
          ),
          if (!_isSignIn) ...[
            const SizedBox(height: 12),
            _buildField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              obscure: true,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _phoneController,
              label: 'Phone Number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildDobField(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: GoogleFonts.dmSans(
                color: Colors.redAccent,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          _buildSubmitButton(),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _toggle,
            child: Text(
              _isSignIn
                  ? "Don't have an account? Sign Up"
                  : 'Already have an account? Sign In',
              style: GoogleFonts.dmSans(
                color: AppColors.gold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            onPrimary: AppColors.background,
            surface: AppColors.surfaceElevated,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Widget _buildDobField() {
    final label = _selectedDob == null
        ? 'Date of Birth'
        : DateFormat('dd MMM yyyy').format(_selectedDob!);
    final labelColor =
        _selectedDob == null ? AppColors.textMuted : AppColors.textPrimary;

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(color: labelColor, fontSize: 14),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14),
      cursorColor: AppColors.gold,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _loading ? null : _submit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _loading ? AppColors.goldSoft : AppColors.gold,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.background,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _isSignIn ? 'Sign In' : 'Create Account',
                  style: GoogleFonts.dmSans(
                    color: AppColors.background,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
