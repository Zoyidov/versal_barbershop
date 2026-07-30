import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/phone_input_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../cubit/auth_cubit.dart';

/// Self sign-up for a new barber account. The account is created immediately
/// but starts `approved: false` - after submitting, `_AuthGate` (app.dart)
/// routes the now-signed-in user to `PendingApprovalPage` until an admin
/// approves them from the user-management screen.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: UzPhoneInputFormatter.initialText);
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parollar mos kelmadi')),
      );
      return;
    }
    final normalizedPhone = Validators.normalizePhone(_phoneController.text)!;
    context.read<AuthCubit>().register(
          phoneNumber: normalizedPhone,
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) => previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      IconButton(
                        alignment: Alignment.centerLeft,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                      ),
                      Icon(Icons.content_cut, color: AppColors.gold, size: 42),
                      const SizedBox(height: 18),
                      Text('Ro\'yxatdan o\'tish', style: AppTextStyles.displayLarge, textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text(
                        'Hisob yaratgach, admin tasdiqlashini kutasiz',
                        style: AppTextStyles.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),
                      GlassCard(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: _nameController,
                              label: 'Ism',
                              validator: (v) => Validators.required(v, fieldName: 'Ism'),
                              prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _phoneController,
                              label: 'Telefon raqami',
                              keyboardType: TextInputType.phone,
                              validator: Validators.phoneNumber,
                              inputFormatters: [UzPhoneInputFormatter()],
                              prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordController,
                              label: 'Parol',
                              obscureText: _obscurePassword,
                              validator: Validators.password,
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _confirmPasswordController,
                              label: 'Parolni tasdiqlang',
                              obscureText: _obscureConfirmPassword,
                              validator: Validators.password,
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                            ),
                            const SizedBox(height: 24),
                            BlocBuilder<AuthCubit, AuthState>(
                              buildWhen: (p, c) => p.submitting != c.submitting,
                              builder: (context, state) {
                                return AppPrimaryButton(
                                  label: 'Ro\'yxatdan o\'tish',
                                  loading: state.submitting,
                                  onPressed: state.submitting ? null : _submit,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
