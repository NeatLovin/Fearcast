import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'popular_page.dart';
import '../services/authentication_services.dart';
import '../utilities/constants.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  void _toggleLoading() {
    setState(() {
      _isLoading = !_isLoading;
    });
  }

  Future<void> _signIn() async {
    String email = emailController.text;
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please fill in all fields',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: errorColor,
        textColor: secondaryColor,
        fontSize: 16.0,
      );
      return;
    }

    _toggleLoading();

    try {
      User? user = await AuthenticationServices().signInWithEmailPassword(
        email,
        password,
      );
      if (user != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PopularPage()),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString(),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: errorColor,
        textColor: secondaryColor,
        fontSize: 16.0,
      );
    } finally {
      _toggleLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('img/auth-background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Card(
            color: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: primaryColor, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 47, bottom: 47),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.welcomeBack,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.email,
                      labelStyle: TextStyle(color: errorColor),
                      filled: true,
                      fillColor: transparentColor,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: errorColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: errorColor),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.password,
                      labelStyle: TextStyle(color: errorColor),
                      filled: true,
                      fillColor: transparentColor,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: errorColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: errorColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(300, 60),
                      backgroundColor: primaryColor,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            AppLocalizations.of(context)!.signIn,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
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
