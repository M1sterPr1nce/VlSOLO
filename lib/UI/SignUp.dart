import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitloch/Logic/AuthController.dart';
import 'package:fitloch/UI/SignIn.dart';
import 'AgeSelection.dart';
import 'dart:async';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthController _authController = AuthController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isVerifyingEmail = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blueAccent),
      ),
      filled: true,
      fillColor: Colors.black,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      errorStyle: TextStyle(color: Colors.redAccent),
    );
  }

  ButtonStyle _getOutlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      side: BorderSide(color: Colors.white),
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      minimumSize: Size(double.infinity, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      User? user = await _authController.signUpWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );

      if (user != null) {
        await user.updateDisplayName(_nameController.text);
        await _authController.saveUserName(user.uid, _nameController.text);

        setState(() {
          _isVerifyingEmail = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification email sent. Please check your inbox.")),
        );

        _waitForEmailVerification(user);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _handleGoogleSignUp() async {
    setState(() => _isLoading = true);

    try {
      User? user = await _authController.signInWithGoogle();
      if (user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AgeSelectionPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-Up failed: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _waitForEmailVerification(User user) {
    Timer.periodic(Duration(seconds: 3), (timer) async {
      await user.reload();
      User? updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        timer.cancel();
        setState(() => _isVerifyingEmail = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Email verified successfully!")),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AgeSelectionPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                      'Create Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    Text(
                      'Please fill in the details to get started',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),

                    SizedBox(height: 40),

                    TextFormField(
                      controller: _nameController,
                      decoration: _getInputDecoration('Full Name'),
                      validator: (value) => 
                          value?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: _getInputDecoration('Email'),
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      decoration: _getInputDecoration('Password'),
                      obscureText: true,
                      validator: _validatePassword,
                    ),

                    SizedBox(height: 24),

                    if (_isVerifyingEmail)
                      Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    else
                      OutlinedButton(
                        style: _getOutlinedButtonStyle(),
                        onPressed: _isLoading ? null : _handleSignUp,
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Sign Up'),
                      ),

                    SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white70)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('or', style: TextStyle(color: Colors.white70)),
                        ),
                        Expanded(child: Divider(color: Colors.white70)),
                      ],
                    ),

                    SizedBox(height: 16),

                    OutlinedButton(
                      style: _getOutlinedButtonStyle(),
                      onPressed: _isLoading ? null : _handleGoogleSignUp,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/icon/Google.png', height: 16),
                          SizedBox(width: 8),
                          Text('Continue with Google'),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    Center(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignInPage(),
                                  ),
                                );
                              },
                        child: Text(
                          'Already have an account? Sign In',
                          style: TextStyle(color: Colors.white70),
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
