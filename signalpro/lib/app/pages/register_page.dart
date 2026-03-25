import 'package:flutter/material.dart';
import 'package:signalpro/app/theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    required this.onLoginTap,
    required this.onRegister,
    super.key,
  });

  final VoidCallback onLoginTap;
  final Future<void> Function({
    required String fullName,
    required String email,
    required String password,
    required String inviteCode,
  }) onRegister;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _inviteController = TextEditingController();

  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  final FocusNode _inviteFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fullNameFocus.addListener(_handleFocusUpdate);
    _emailFocus.addListener(_handleFocusUpdate);
    _passwordFocus.addListener(_handleFocusUpdate);
    _confirmFocus.addListener(_handleFocusUpdate);
    _inviteFocus.addListener(_handleFocusUpdate);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteController.dispose();

    _fullNameFocus
      ..removeListener(_handleFocusUpdate)
      ..dispose();
    _emailFocus
      ..removeListener(_handleFocusUpdate)
      ..dispose();
    _passwordFocus
      ..removeListener(_handleFocusUpdate)
      ..dispose();
    _confirmFocus
      ..removeListener(_handleFocusUpdate)
      ..dispose();
    _inviteFocus
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
    if (_isSubmitting) {
      return;
    }

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final inviteCode = _inviteController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    if (fullName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name must be at least 2 characters.')),
      );
      return;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    if (inviteCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite code is required.')),
      );
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms to continue.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      await widget.onRegister(
        fullName: fullName,
        email: email,
        password: password,
        inviteCode: inviteCode,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                          children: [
                            const Center(
                              child: Image(image: AssetImage('logo.png'), width: 224),
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
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Center(
                                        child: Text(
                                          'Join SignalPro to access exclusive crypto trading signals.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: AppColors.textSecondary),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const _Label('FULL NAME'),
                                      const SizedBox(height: 6),
                                      _Input(
                                        controller: _fullNameController,
                                        focusNode: _fullNameFocus,
                                        prefix: Icons.person_outline_rounded,
                                        hint: 'Your full name',
                                        textInputAction: TextInputAction.next,
                                        onSubmitted: (_) => _emailFocus.requestFocus(),
                                      ),
                                      const SizedBox(height: 12),
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
                                      const _Label('SECURE PASSWORD'),
                                      const SizedBox(height: 6),
                                      _Input(
                                        controller: _passwordController,
                                        focusNode: _passwordFocus,
                                        prefix: Icons.lock_outline_rounded,
                                        hint: '••••••••',
                                        textInputAction: TextInputAction.next,
                                        obscureText: _obscurePassword,
                                        onSubmitted: (_) => _confirmFocus.requestFocus(),
                                        suffix: IconButton(
                                          onPressed: () {
                                            setState(() => _obscurePassword = !_obscurePassword);
                                          },
                                          splashRadius: 18,
                                          icon: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 180),
                                            transitionBuilder: (child, animation) =>
                                                FadeTransition(opacity: animation, child: child),
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
                                      const _Label('CONFIRM PASSWORD'),
                                      const SizedBox(height: 6),
                                      _Input(
                                        controller: _confirmPasswordController,
                                        focusNode: _confirmFocus,
                                        prefix: Icons.verified_user_outlined,
                                        hint: '••••••••',
                                        textInputAction: TextInputAction.next,
                                        obscureText: _obscureConfirm,
                                        onSubmitted: (_) => _inviteFocus.requestFocus(),
                                        suffix: IconButton(
                                          onPressed: () {
                                            setState(() => _obscureConfirm = !_obscureConfirm);
                                          },
                                          splashRadius: 18,
                                          icon: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 180),
                                            transitionBuilder: (child, animation) =>
                                                FadeTransition(opacity: animation, child: child),
                                            child: Icon(
                                              _obscureConfirm
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              key: ValueKey<bool>(_obscureConfirm),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const _Label('INVITE CODE (REQUIRED)'),
                                      const SizedBox(height: 6),
                                      _Input(
                                        controller: _inviteController,
                                        focusNode: _inviteFocus,
                                        prefix: Icons.confirmation_number_outlined,
                                        hint: 'SIG-XXXX-XXXX',
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => _submit(),
                                      ),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Row(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 160),
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5),
                                                color: _acceptTerms
                                                    ? AppColors.primary
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: _acceptTerms
                                                      ? AppColors.primary
                                                      : AppColors.textMuted,
                                                ),
                                              ),
                                              child: _acceptTerms
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      size: 14,
                                                      color: AppColors.background,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            const Expanded(
                                              child: Text(
                                                'I agree to the Terms of Service and Privacy Policy.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _AnimatedRegisterButton(
                                        onPressed: _submit,
                                        isLoading: _isSubmitting,
                                      ),
                                      const SizedBox(height: 12),
                                      Center(
                                        child: TextButton(
                                          onPressed: _isSubmitting ? null : widget.onLoginTap,
                                          child: const Text(
                                            'Already have an account? Login',
                                            style: TextStyle(color: AppColors.textSecondary),
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
                                _Foot(
                                  text:
                                      '© ${DateTime.now().year} SignalPro. All rights reserved.',
                                ),
                              ],
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

class _AnimatedRegisterButton extends StatefulWidget {
  const _AnimatedRegisterButton({required this.onPressed, required this.isLoading});

  final Future<void> Function() onPressed;
  final bool isLoading;

  @override
  State<_AnimatedRegisterButton> createState() => _AnimatedRegisterButtonState();
}

class _AnimatedRegisterButtonState extends State<_AnimatedRegisterButton> {
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
            child: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.background),
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          color: AppColors.background,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.background,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
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
      style: const TextStyle(
        fontSize: 10,
        color: AppColors.textMuted,
        letterSpacing: 1,
      ),
    );
  }
}
