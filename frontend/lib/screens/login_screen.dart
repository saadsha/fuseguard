import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoginMode = true;
  String _selectedRole = 'Viewer'; // Default role for registration

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If authenticated, navigate to dashboard
    if (authProvider.isAuthenticated) {
      // Use addPostFrameCallback to avoid state modification during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 64, color: Colors.blue[800]),
                  SizedBox(height: 16),
                  Text(
                    'FuseGuard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Transformer Monitoring System',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 32),
                  if (authProvider.error != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        authProvider.error!,
                        style: TextStyle(color: Colors.red[800]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (!_isLoginMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter your name' : null,
                      ),
                    ),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => 
                      value!.isEmpty ? 'Please enter email' : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => 
                      value!.isEmpty ? 'Please enter password' : null,
                  ),
                  if (!_isLoginMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16, top: 16),
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['Engineer', 'Viewer'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedRole = newValue!;
                          });
                        },
                      ),
                    )
                  else
                    SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                if (_isLoginMode) {
                                  await authProvider.login(
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                                } else {
                                  await authProvider.register(
                                    name: _nameController.text,
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                    role: _selectedRole,
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isLoginMode ? 'Login' : 'Register',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  SizedBox(height: 24), // Increased padding
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      side: BorderSide(color: Colors.blue[800]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isLoginMode
                          ? 'Need an account? Register here'
                          : 'Already have an account? Login here',
                      style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                       await authProvider.logout();
                       setState((){
                         authProvider.error; // clear
                       });
                    },
                    child: Text(
                      'Clear Stale Session',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
