import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../cubit/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    debugPrint('[LoginPage] Sign in button pressed. raw phone="${_phoneController.text}"');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[LoginPage] Form validation failed - not submitting.');
      return;
    }
    final normalizedPhone = Validators.normalizePhone(_phoneController.text)!;
    debugPrint('[LoginPage] Validation passed. normalizedPhone=$normalizedPhone - calling AuthCubit.login()');
    context.read<AuthCubit>().login(
          phoneNumber: normalizedPhone,
          password: _passwordController.text,
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
                      Icon(Icons.content_cut, color: AppColors.gold, size: 42),
                      const SizedBox(height: 18),
                      Text('Versal Barbershop', style: AppTextStyles.displayLarge, textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text(
                        'Uchrashuvlarni boshqarish uchun tizimga kiring',
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
                              controller: _phoneController,
                              label: 'Telefon raqami',
                              hint: '90 123 45 67',
                              keyboardType: TextInputType.phone,
                              validator: Validators.phoneNumber,
                              prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            BlocBuilder<AuthCubit, AuthState>(
                              buildWhen: (p, c) => p.submitting != c.submitting,
                              builder: (context, state) {
                                return AppTextField(
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
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            BlocBuilder<AuthCubit, AuthState>(
                              buildWhen: (p, c) => p.submitting != c.submitting,
                              builder: (context, state) {
                                return AppPrimaryButton(
                                  label: 'Kirish',
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
