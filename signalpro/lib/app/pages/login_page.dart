import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/auth_language_switcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.onLogin,
    required this.onRegister,
    required this.isLoading,
    super.key,
  });

  final Future<String?> Function({
    required String email,
    required String password,
  })
  onLogin;

  final VoidCallback onRegister;
  final bool isLoading;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_handleFocusUpdate);
    _passwordFocus.addListener(_handleFocusUpdate);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleFocusUpdate() => setState(() {});

  Future<void> _submit() async {
    if (widget.isLoading) return;

    final l10n = context.l10n;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('Please enter email and password.'))),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    final error = await widget.onLogin(email: email, password: password);

    if (!mounted || error == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.tr(error))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.surfaceSoft,
              AppColors.backgroundSecondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 260),
              padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(
                      scrollbars: false,
                      dragDevices: <PointerDeviceKind>{
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.stylus,
                        PointerDeviceKind.unknown,
                      },
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: AuthLanguageSwitcher(),
                              ),
                              const Spacer(),
                              const Center(
                                child: Image(
                                  image: AssetImage('assets/logo.png'),
                                  width: 200,
                                ),
                              ),
                              const SizedBox(height: 20),

                              /// 🔥 LOGIN CARD
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 460,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 30,
                                        spreadRadius: -10,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Text(
                                          l10n.tr('Welcome Back'),
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Center(
                                        child: Text(
                                          l10n.tr(
                                            'Enter your credentials to access your account.',
                                          ),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      _Label(l10n.tr('EMAIL ADDRESS')),
                                      const SizedBox(height: 6),
                                      _Input(
                                        controller: _emailController,
                                        focusNode: _emailFocus,
                                        prefix: Icons.mail_outline_rounded,
                                        hint: l10n.tr('name@company.com'),
                                        textInputAction: TextInputAction.next,
                                        onSubmitted: (_) =>
                                            _passwordFocus.requestFocus(),
                                      ),

                                      const SizedBox(height: 12),

                                      Row(
                                        children: [
                                          _Label(l10n.tr('PASSWORD')),
                                          const Spacer(),
                                          Text(
                                            l10n.tr('Forgot Password?'),
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      _Input(
                                        controller: _passwordController,
                                        focusNode: _passwordFocus,
                                        prefix: Icons.lock_outline_rounded,
                                        hint: '••••••••',
                                        obscureText: _obscurePassword,
                                        onSubmitted: (_) => _submit(),
                                        suffix: IconButton(
                                          iconSize: 20,
                                          onPressed: () {
                                            setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            );
                                          },
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      /// Remember me
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () => setState(
                                              () => _rememberMe = !_rememberMe,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 18,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          5,
                                                        ),
                                                    color: _rememberMe
                                                        ? AppColors.primary
                                                        : Colors.transparent,
                                                    border: Border.all(
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                  child: _rememberMe
                                                      ? const Icon(
                                                          Icons.check,
                                                          size: 14,
                                                          color: Colors.black,
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  l10n.tr('Remember me'),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      /// 🔥 LOGIN BUTTON
                                      GestureDetector(
                                        onTap: widget.isLoading
                                            ? null
                                            : _submit,
                                        child: Container(
                                          height: 52,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppColors.primary,
                                                AppColors.primaryBright,
                                                Color(0xFFB8860B),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withOpacity(0.3),
                                                blurRadius: 18,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: widget.isLoading
                                                ? SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        const CircularProgressIndicator(
                                                          color: Colors.black,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        l10n.tr('Login'),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(
                                                        Icons
                                                            .arrow_forward_rounded,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      Center(
                                        child: TextButton(
                                          onPressed: widget.onRegister,
                                          child: Text(
                                            l10n.tr(
                                              "Don't have an account? Register",
                                            ),
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const Spacer(),

                              _Foot(
                                text: l10n.tr(
                                  '\u00A9 {year} GoldX. All rights reserved.',
                                  params: <String, String>{
                                    'year': DateTime.now().year.toString(),
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.focusNode,
    required this.prefix,
    required this.hint,
    this.suffix,
    this.obscureText = false,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData prefix;
  final String hint;
  final Widget? suffix;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surfaceSoft,
        prefixIcon: Icon(
          prefix,
          size: 20,
          color: focused ? AppColors.primary : AppColors.textMuted,
        ),
        suffixIcon: suffix,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _Foot extends StatelessWidget {
  const _Foot({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
    );
  }
}
