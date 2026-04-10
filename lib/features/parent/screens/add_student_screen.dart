import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/location_service.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _studentNameController = TextEditingController();
  final _unitCodeController = TextEditingController(); // Código de la Unidad / Bus
  final MobileScannerController _scannerController = MobileScannerController();

  bool _isScanning = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _studentNameController.dispose();
    _unitCodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _registerStudent() async {
    final name = _studentNameController.text.trim();
    final unitCode = _unitCodeController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Debes ingresar el nombre del estudiante');
      return;
    }
    if (unitCode.isEmpty) {
      setState(() => _errorMessage = 'Debes ingresar el número de la unidad escolar');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      // Pedimos ubicación para fijarla como la Parada del Estudiante
      final locationService = LocationService();
      
      setState(() => _errorMessage = 'Obteniendo coordenadas GPS fijas para la parada...');
      final position = await locationService.getCurrentPosition();
      
      if (position == null) {
        throw Exception("Es obligatorio conceder permisos de GPS para fijar la parada de la casa.");
      }

      // Extraer UID del padre (Usuario actual logueado)
      final parentUid = await firebaseService.getCurrentUserId();
      
      if (parentUid == null) throw Exception("Sesión no válida");

      setState(() => _errorMessage = 'Guardando datos en el servidor...');
      // Guardar estudiante en base de datos
      await firebaseService.registerStudent(
        parentId: parentUid,
        studentName: name,
        unitCode: unitCode,
        stopLat: position.latitude,
        stopLng: position.longitude,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estudiante registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Volver al dashboard
    } catch (e) {
      setState(() => _errorMessage = 'Error al registrar: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onQRScanned(BarcodeCapture capture) {
    if (capture.barcodes.isNotEmpty) {
      final String code = capture.barcodes.first.rawValue ?? '';
      if (code.isNotEmpty) {
        setState(() {
          _unitCodeController.text = code;
          _isScanning = false;
          _errorMessage = 'Código escaneado correctamente.'; // Feedback positivo temporal
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Añadir Estudiante',
          style: GoogleFonts.publicSans(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView( // 🔴 Esto garantiza que se adapte al tamaño sin errores
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Datos del Estudiante',
                style: GoogleFonts.publicSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vincula a tu hijo con su ruta escolar utilizando el escáner QR o ingresando la unidad manualmente.',
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Nombre del Estudiante
              Text(
                'NOMBRE DEL ESTUDIANTE',
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _studentNameController,
                style: GoogleFonts.publicSans(),
                onChanged: (_) => setState(() => _errorMessage = null),
                decoration: InputDecoration(
                  hintText: 'Ej. Mateo Silva',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Unidad Educativa / Código Bus
              Text(
                'UNIDAD ESCOLAR / CÓDIGO',
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              // Input y Lector QR
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _unitCodeController,
                      style: GoogleFonts.publicSans(),
                      onChanged: (_) => setState(() => _errorMessage = null),
                      decoration: InputDecoration(
                        hintText: 'Ej. UNIDAD-42',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.directions_bus, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      setState(() {
                        FocusScope.of(context).unfocus(); // Ocultar teclado
                        _isScanning = !_isScanning;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        color: _isScanning ? Colors.red : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (_isScanning ? Colors.red : AppColors.primaryContainer).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: Icon(
                        _isScanning ? Icons.close : Icons.qr_code_scanner,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Visor del Escáner QR
              if (_isScanning)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onQRScanned,
                      ),
                      Center(
                        child: Icon(Icons.crop_free, size: 100, color: Colors.white.withOpacity(0.5)),
                      )
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Mostrar errores
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _errorMessage!.contains('correctamente') 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _errorMessage!.contains('correctamente') 
                            ? Icons.check_circle 
                            : Icons.warning, 
                        color: _errorMessage!.contains('correctamente') 
                            ? Colors.green 
                            : Colors.red
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: _errorMessage!.contains('correctamente') 
                                ? Colors.green 
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Botón Guardar
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _registerStudent,
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(
                  _isLoading ? 'GUARDANDO...' : 'REGISTRAR ESTUDIANTE',
                  style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: const Color(0xFF221B00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
