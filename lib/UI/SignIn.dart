import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitloch/Logic/AuthController.dart';
import 'package:fitloch/UI/SignUp.dart';
import 'HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final AuthController _authController = AuthController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
  }



  // Auto sign in
  _autoSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final password = prefs.getString('password');
    
    if (email != null && password != null) {
      setState(() => _isLoading = true);
      
      try {
        User? user = await _authController.signInWithEmailPassword(email, password);

        if (user != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ReadingProgressScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sign-in failed")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  _checkRememberMe() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _rememberMe = prefs.getBool('rememberMe') ?? true;
  });

  if (_rememberMe) {
    _autoSignIn(); 
  }
}

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Custom text field style
  InputDecoration _getInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white, width: 1), 
    ),
    filled: true,
    fillColor: const Color.fromARGB(0, 255, 255, 255), // Light fill for contrast
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    errorStyle: TextStyle(color: Colors.red[700]),

    // ✅ Fix: Ensure border is visible when an error occurs
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white, width: 1), 
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color.fromARGB(255, 255, 255, 255), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2), 
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  );
  }



  // Custom button style
  ButtonStyle _getPrimaryButtonStyle({Color? backgroundColor}) {
    return OutlinedButton.styleFrom(
      
      backgroundColor: backgroundColor ?? Color.fromARGB(0, 255, 255, 255),
      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      minimumSize: Size(double.infinity, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        
      ),
    );
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Handle sign in
  void _handleSignIn() async {
    if (!mounted || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      User? user = await _authController.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (user != null) {
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('email', _emailController.text);
          prefs.setString('password', _passwordController.text);
          prefs.setBool('rememberMe', true);
        }

        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ReadingProgressScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign-in failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Handle Google sign in
  void _handleGoogleSignIn() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      User? user = await _authController.signInWithGoogle();

      if (!mounted) return;

      if (user != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ReadingProgressScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Sign-In failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Handle forgot password
  void _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email first")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset email sent. Check your inbox."),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 20, 20, 20),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40),
                    
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: const Color.fromARGB(221, 255, 255, 255),
                      ),
                    ),
                    
                    Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    
                    SizedBox(height: 40),
                    
                    TextFormField(
                      controller: _emailController,
                      decoration: _getInputDecoration('Email'),
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                    ),
                    SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _passwordController,
                      decoration: _getInputDecoration('Password'),
                      obscureText: true,
                      validator: _validatePassword,
                      enabled: !_isLoading,
                    ),
                    
                    SizedBox(height: 16),
                    
                    Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(
      children: [
      ],
    ),
    TextButton(
      onPressed: _isLoading ? null : _handleForgotPassword,
      child: Text('Forgot Password?', style: TextStyle(color: Colors.white)),
    ),
  ],
),

                    
                    
                    SizedBox(height: 24),
                    
                    OutlinedButton(
                      style: _getPrimaryButtonStyle(),
                      onPressed: _isLoading ? null : _handleSignIn,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text('Sign In'),
                    ),
                    
                    SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    OutlinedButton.icon(
  style: OutlinedButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: 12),
    minimumSize: Size(double.infinity, 45),
    side: BorderSide(color: const Color.fromARGB(255, 255, 255, 255)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  onPressed: _isLoading ? null : _handleGoogleSignIn,
  icon: Image.asset('assets/icon/Google.png', height: 16), // Add Google logo
  label: Text('Continue with Google', style: TextStyle(color: Colors.white)),
),

                    
                    SizedBox(height: 24),
                    
                    Center(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SignUpPage(),
                                  ),
                                );
                              },
                        child: Text(
                          'Don\'t have an account? Sign Up',
                          style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
