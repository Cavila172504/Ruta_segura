import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/driver/screens/driver_dashboard_screen.dart';
import '../../features/parent/screens/parent_dashboard_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';

enum AuthMode { login, register, forgotPassword }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  AuthMode _authMode = AuthMode.login;
  bool _obscurePassword = true;
  String _selectedRole = 'parent';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingrese su correo electrónico');
      return;
    }
    
    if (_authMode != AuthMode.forgotPassword && password.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingrese su contraseña');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      
      if (_authMode == AuthMode.forgotPassword) {
        await firebaseService.sendPasswordReset(email);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enlace de recuperación enviado. Revisa tu correo.')),
        );
        setState(() => _authMode = AuthMode.login);
        return;
      }

      UserCredential? creds;
      
      if (_authMode == AuthMode.login) {
        creds = await firebaseService.signIn(email, password);
      } else {
        creds = await firebaseService.signUp(email, password, _selectedRole);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada excitósamente. Por favor, revisa tu correo para verificar la cuenta antes de ingresar.')),
        );
        setState(() {
          _authMode = AuthMode.login;
          _passwordController.clear();
        });
        return;
      }
      
      if (creds?.user != null) {
        final role = await firebaseService.getUserRole(creds!.user!.uid);
        print('✅ LOGIN EXITOSO: Rol detectado -> $role');
        
        if (!mounted) return;
        
        // Routing temporal hasta tener GoRouter listo
        if (role == 'driver') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DriverDashboardScreen()));
        } else if (role == 'parent') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ParentDashboardScreen()));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
        }
      }
    } catch (e) {
      setState(() {
        final errorStr = e.toString();
        if (errorStr.contains('verificado')) {
           _errorMessage = 'Correo no verificado. Revisa SPAM (Acabamos de reenviarlo).';
        } else if (errorStr.contains('email-already-in-use')) {
           _errorMessage = 'Este correo ya está registrado. Por favor entra en "Ingresar".';
        } else {
           _errorMessage = 'Credenciales inválidas o error de conexión al intentar acceder.';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Decorative lines
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(height: 4, color: AppColors.primaryContainer),
          ),
          Positioned(
            top: 0, bottom: 0, left: 0,
            child: Container(width: 4, color: AppColors.secondary),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo Section
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ]
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            color: AppColors.primaryContainer,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'RUTASEGURA',
                          style: GoogleFonts.publicSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 4,
                          width: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Plataforma de Transporte Escolar',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.publicSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Mensaje de Error
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Form Container 
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Input de Correo
                          Text(
                            'CORREO ELECTRÓNICO',
                            style: GoogleFonts.publicSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.publicSans(color: AppColors.onSurface),
                            decoration: InputDecoration(
                              hintText: 'usuario@rutasegura.com',
                              hintStyle: TextStyle(color: AppColors.outline.withOpacity(0.5)),
                              prefixIcon: const Icon(Icons.mail, color: Colors.grey),
                              filled: true,
                              fillColor: AppColors.surfaceContainerLowest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Input de Contraseña
                          if (_authMode != AuthMode.forgotPassword) ...[
                            Text(
                              'CONTRASEÑA',
                              style: GoogleFonts.publicSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.publicSans(color: AppColors.onSurface),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                hintStyle: TextStyle(color: AppColors.outline.withOpacity(0.5)),
                                prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLowest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),
                          // Optional Role Selector
                          if (_authMode == AuthMode.register) ...[
                            Text(
                              'ROL DEL USUARIO',
                              style: GoogleFonts.publicSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRole,
                                  isExpanded: true,
                                  dropdownColor: AppColors.surfaceContainerLowest,
                                  items: const [
                                    DropdownMenuItem(value: 'parent', child: Text('Padre de familia')),
                                    DropdownMenuItem(value: 'driver', child: Text('Conductor')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedRole = val);
                                  },
                                ),
                              ),
                            ),
                          ] else if (_authMode == AuthMode.login) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _authMode = AuthMode.forgotPassword;
                                    _errorMessage = null;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.secondary,
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  '¿OLVIDÓ SU CONTRASEÑA?',
                                  style: GoogleFonts.publicSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Botón Ingresar / Registrar
                          InkWell(
                            onTap: _isLoading ? null : _handleAuth,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.buttonMetallic,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24, width: 24,
                                      child: CircularProgressIndicator(color: Color(0xFF221B00), strokeWidth: 2),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _authMode == AuthMode.login 
                                            ? 'INGRESAR' 
                                            : _authMode == AuthMode.register 
                                              ? 'REGISTRARME'
                                              : 'ENVIAR CORREO',
                                          style: GoogleFonts.publicSans(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1,
                                            color: const Color(0xFF221B00),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.arrow_forward,
                                          color: Color(0xFF221B00),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Toggle Mode
                          if (_authMode == AuthMode.login)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _authMode = AuthMode.register;
                                  _errorMessage = null;
                                });
                              },
                              child: Text(
                                '¿No tienes cuenta? Crear una ahora',
                                style: GoogleFonts.publicSans(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _authMode = AuthMode.login;
                                  _errorMessage = null;
                                });
                              },
                              icon: const Icon(Icons.arrow_back, color: AppColors.primary, size: 16),
                              label: Text(
                                'Volver al inicio de sesión',
                                style: GoogleFonts.publicSans(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Copyright Footer
                    Text(
                      'Al ingresar, usted acepta los términos de seguridad vial y monitoreo satelital en tiempo real de la plataforma RutaSegura.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.publicSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary, 
                            shape: BoxShape.circle
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SENTINEL SYSTEM V.2.4',
                          style: GoogleFonts.publicSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
