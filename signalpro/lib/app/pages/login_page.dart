import 'package:flutter/material.dart';
import 'package:signalpro/app/theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.onLogin,
    required this.onRegister,
    required this.isLoading,
    super.key,
  });

  final Future<String?> Function({required String email, required String password}) onLogin;
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
    _emailFocus
      ..removeListener(_handleFocusUpdate)
      ..dispose();
    _passwordFocus
      ..removeListener(_handleFocusUpdate)
      ..dispose();
    super.dispose();
  }

  void _handleFocusUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (widget.isLoading) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    final error = await widget.onLogin(email: email, password: password);

    if (!mounted || error == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1220), Color(0xFF0D1830), Color(0xFF0B1220)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
              child: Column(
                children: [
                  // const SizedBox(height: 8),
                  const Center(
                    child: Image(
                      image: AssetImage('logo.png'),
                      width: 224
                    ),
                  ),
                  const Spacer(),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 20, end: 0),
                    builder: (context, offsetY, child) {
                      return Transform.translate(
                        offset: Offset(0, offsetY),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: 1,
                          child: child,
                        ),
                      );
                    },
                    child: ConstrainedBox(
                      
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Container(
                        
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              blurRadius: 30,
                              spreadRadius: -10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                'Enter your credentials to access your account.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const _Label('EMAIL ADDRESS'),
                            const SizedBox(height: 6),
                            _Input(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              prefix: Icons.mail_outline_rounded,
                              hint: 'name@company.com',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: const [
                                _Label('PASSWORD'),
                                Spacer(),
                                Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: AppColors.primaryBright,
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
                              textInputAction: TextInputAction.done,
                              obscureText: _obscurePassword,
                              onSubmitted: (_) => _submit(),
                              suffix: IconButton(
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                splashRadius: 18,
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                  child: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    key: ValueKey<bool>(_obscurePassword),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => setState(
                                    () => _rememberMe = !_rememberMe,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 160,
                                        ),
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                          color: _rememberMe
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: _rememberMe
                                                ? AppColors.primary
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                        child: _rememberMe
                                            ? const Icon(
                                                Icons.check_rounded,
                                                size: 14,
                                                color: AppColors.background,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Remember me',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _AnimatedLoginButton(
                              onPressed: _submit,
                              isLoading: widget.isLoading,
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: widget.isLoading ? null : widget.onRegister,
                                child: const Text(
                                  'Don\'t have an account? Register',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // auto get current year
                      _Foot(text: '© ${DateTime.now().year} SignalPro. All rights reserved.'),
                    ],
                  ),
                ],
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
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  final IconData prefix;
  final Widget? suffix;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: -8,
                ),
              ]
            : const [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.background,
          prefixIcon: Icon(
            prefix,
            size: 20,
            color: focused ? AppColors.primaryBright : AppColors.textMuted,
          ),
          suffixIcon: suffix,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLoginButton extends StatefulWidget {
  const _AnimatedLoginButton({required this.onPressed, required this.isLoading});

  final Future<void> Function() onPressed;
  final bool isLoading;

  @override
  State<_AnimatedLoginButton> createState() => _AnimatedLoginButtonState();
}

class _AnimatedLoginButtonState extends State<_AnimatedLoginButton> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapCancel() => setState(() => _pressed = false);
  Future<void> _onTapUp(TapUpDetails _) async {
    if (widget.isLoading) {
      setState(() => _pressed = false);
      return;
    }

    setState(() => _pressed = false);
    await widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : _onTapDown,
      onTapUp: widget.isLoading ? null : _onTapUp,
      onTapCancel: widget.isLoading ? null : _onTapCancel,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _pressed ? 0.98 : 1,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryBright],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 18,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Center(
            child: _LoginButtonContent(isLoading: widget.isLoading),
          ),
        ),
      ),
    );
  }
}

class _LoginButtonContent extends StatelessWidget {
  const _LoginButtonContent({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
        ),
      );
    }

    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.login_rounded, color: AppColors.background, size: 18),
        SizedBox(width: 8),
        Text(
          'Login',
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
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
      style: const TextStyle(
        fontSize: 10,
        color: AppColors.textMuted,
        letterSpacing: 1,
      ),
    );
  }
}
