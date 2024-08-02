import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'Homepage.dart';
import 'RegistrationPage.dart'; // Import the SignUpPage

/*
 * This is the entry point for the TruckIt driver application. The file initializes Firebase,
 * sets up the main structure of the app, and handles user authentication. The main widget is MyApp,
 * which sets the theme and login page. The login page (LoginPage) contains the login form,
 * and navigates to the Homepage upon successful login or to the RegistrationPage for new truck registration.
 */

/*
 * Main entry point of the application
 * Ensures widgets are initialized and initializes Firebase begore running app
 */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase initialized');
  runApp(const MyApp());
}

/*
 * Main application widget
 * Sets up the page shown on launch, the login page
 */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building MyApp widget');
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C1C1E),
        ),
        body: const LoginPage(),
      ),
    );
  }
}

/*
 * Login page widget
 * Contains the login form and option to navigate to registration page
 */
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1C1C1E),
      resizeToAvoidBottomInset: true, // Ensures the UI adjusts when the keyboard is shown
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 80),
            Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.0,
                fontFamily: 'Raleway',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            LoginForm(),
          ],
        ),
      ),
    );
  }
}

/*
 * Login form widget
 * Manages user input for email and password
 * Handles login logic
 */
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

/*
 * State class for LoginForm
 * Handles the logic state for user login
 */
class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _errorMessage = '';

  // Login with user authenication in Firebase
  // Only email sign in allowed
  Future<void> _login() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      print('Signed in as ${userCredential.user?.uid}');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Homepage()),
      );
    } catch (e) {
      print('Error signing in: $e');
      setState(() {
        _errorMessage = 'Login failed. Please check your credentials.';
      });
    }
  }

  // Build method for rendering the login form
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Email input field
        TextFieldWidget(
          controller: _emailController,
          hintText: 'Email',
        ),
        const SizedBox(height: 16.0),
        TextFieldWidget(
          // Password input field
          controller: _passwordController,
          hintText: 'Password',
          obscureText: true,
        ),
        const SizedBox(height: 16.0),
        // Login button
        ElevatedButton(
          onPressed: _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
          child: const Icon(
            Icons.arrow_forward,
            color: Colors.white,
          ),
        ),
        // Display error message if login fails
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        const SizedBox(height: 50.0),
        const DividerWithText(),
        const SizedBox(height: 50.0),
        ElevatedButton(
          // Button to navigato to registration page
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegistrationPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            minimumSize: Size(300, 50),
          ),
          child: const Text(
            'Register Your Truck',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 19.0,
            ),
          ),
        ),
      ],
    );
  }
}

// Text field attributes
class TextFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const TextFieldWidget({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.0),
        filled: true,
        fillColor: Colors.white24,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      keyboardAppearance: Brightness.dark, 
    );
  }
}

/*
 * Divider widget for 'Or' text
 */
class DividerWithText extends StatelessWidget {
  const DividerWithText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(
          // Left divider
          child: Divider(
            color: Colors.white,
            thickness: 1,
            indent: 50,
            endIndent: 10,
          ),
        ),
        Text(
          'or',
          style: TextStyle(color: Colors.white, fontSize: 18.0),
        ),
        Expanded(
          // Right divider
          child: Divider(
            color: Colors.white,
            thickness: 1,
            indent: 10,
            endIndent: 50,
          ),
        ),
      ],
    );
  }
}
