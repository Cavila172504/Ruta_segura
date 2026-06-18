import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/services/notification_service.dart';
import 'parent_map_picker_screen.dart';
import '../../../core/providers/parent_member_utils.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key, this.fixedUnitCode});

  /// Si se pasa, el estudiante se registra solo en este colegio (dashboard activo).
  final String? fixedUnitCode;

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _studentNameController = TextEditingController();
  final _cedulaController = TextEditingController(); // Cédula del Padre
  final _parentNameController = TextEditingController(); // Nombre del Representante
  final _parentEmailController = TextEditingController(); // Email del Representante
  final _unitCodeController = TextEditingController(); // Código de la Unidad / Bus
  final MobileScannerController _scannerController = MobileScannerController();

  LatLng? _selectedLocation; // Ubicación en el mapa
  String? _selectedGrade; // Grado/Curso
  String? _selectedServiceType; // Tipo de Recorrido
  String? _schoolName; // Nombre del colegio detectado

  bool _isScanning = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isValidatingUnit = false;

  final List<String> _grades = [
    'Inicial 1', 'Inicial 2', 'Primero de Básica', 
    'Segundo de Básica', 'Tercero de Básica', 'Cuarto de Básica',
    'Quinto de Básica', 'Sexto de Básica', 'Séptimo de Básica',
    'Octavo de Básica', 'Noveno de Básica', 'Décimo de Básica',
    'Primero de Bachillerato', 'Segundo de Bachillerato', 'Tercero de Bachillerato'
  ];

  final List<String> _serviceTypes = [
    'Completo (Ida y Retorno)',
    'Solo Entrada (Mañana)',
    'Solo Salida (Tarde)',
    'Combinado / Especial'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.fixedUnitCode != null && widget.fixedUnitCode!.trim().isNotEmpty) {
      final code = widget.fixedUnitCode!.trim().toUpperCase();
      _unitCodeController.text = code;
      WidgetsBinding.instance.addPostFrameCallback((_) => _validateUnit(code));
    }
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _cedulaController.dispose();
    _parentNameController.dispose();
    _parentEmailController.dispose();
    _unitCodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _validateUnit(String code) async {
    if (code.isEmpty) {
      if (!mounted) return;
      setState(() {
        _schoolName = null;
        _errorMessage = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isValidatingUnit = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('companies').doc(code.toUpperCase().trim()).get();
      if (!mounted) return;
      if (doc.exists) {
        final name = doc.data()?['name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          setState(() {
            _schoolName = name.trim();
            _errorMessage = null;
          });
        } else {
          setState(() {
            _schoolName = null;
            _errorMessage =
                'Este colegio no está configurado correctamente. Contacta a tu institución.';
          });
        }
      } else {
        setState(() {
          _schoolName = null;
          _errorMessage = 'El código de unidad no existe en nuestros registros.';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _schoolName = null);
    } finally {
      if (mounted) setState(() => _isValidatingUnit = false);
    }
  }

  Future<void> _registerStudent() async {
    FocusScope.of(context).unfocus(); // Ocultar teclado al guardar
    
    final name = _studentNameController.text.trim();
    final cedula = _cedulaController.text.trim();
    final unitCode = _unitCodeController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Debes ingresar el nombre del estudiante');
      return;
    }
    if (_selectedGrade == null) {
      setState(() => _errorMessage = 'Debes seleccionar el grado/curso');
      return;
    }
    if (_selectedServiceType == null) {
      setState(() => _errorMessage = 'Debes seleccionar el tipo de recorrido');
      return;
    }
    if (cedula.isEmpty) {
      setState(() => _errorMessage = 'Debes ingresar la cédula del padre de familia');
      return;
    }
    if (unitCode.isEmpty) {
      setState(() => _errorMessage = 'Debes ingresar el número de la unidad escolar');
      return;
    }
    if (_schoolName == null) {
      setState(() => _errorMessage =
          _errorMessage ?? 'Debes ingresar un código de colegio válido y esperar la confirmación.');
      return;
    }
    if (_selectedLocation == null) {
      setState(() => _errorMessage = 'Debes fijar la ubicación de parada en el mapa');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      
      // Extraer UID del padre (Usuario actual logueado)
      final parentUid = await authRepo.getCurrentUserId();
      if (parentUid == null) throw Exception("Sesión no válida");

      setState(() => _errorMessage = 'Guardando estudiante...');

      final docId = unitCode.trim().toUpperCase();
      final studentRepo = ref.read(studentRepositoryProvider);

      await studentRepo.registerStudent(
        parentId: parentUid,
        studentName: name,
        unitCode: docId,
        cedulaPadre: cedula,
        parentName: _parentNameController.text.trim(),
        parentEmail: _parentEmailController.text.trim(),
        stopLat: _selectedLocation!.latitude,
        stopLng: _selectedLocation!.longitude,
        grade: _selectedGrade,
        serviceType: _selectedServiceType,
      );

      ref.invalidate(linkedUnitCodesProvider);
      ref.invalidate(activeUnitCodeProvider);
      ref.invalidate(parentStudentsProvider);
      ref.invalidate(userProfileProvider);

      try {
        await NotificationService()
            .subscribeToBus(unitCode)
            .timeout(const Duration(seconds: 8));
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Estudiante registrado. El colegio debe aprobar la inscripcion.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            'Error al registrar: ${friendlyNetworkError(e)}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onQRScanned(BarcodeCapture capture) {
    if (capture.barcodes.isNotEmpty) {
      String code = capture.barcodes.first.rawValue ?? '';
      if (code.isNotEmpty) {
        // Soporte para protocolo de vinculación segura
        if (code.startsWith('RUTASEGURA:UNIT:')) {
          code = code.replaceFirst('RUTASEGURA:UNIT:', '');
        }
        code = code.trim().toUpperCase();

        setState(() {
          _unitCodeController.text = code;
          _isScanning = false;
          _schoolName = null;
        });
        _validateUnit(code);
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
              const SizedBox(height: 24),

              // Cédula del Padre
              Text(
                'CÉDULA DEL PADRE DE FAMILIA',
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cedulaController,
                style: GoogleFonts.publicSans(),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _errorMessage = null),
                decoration: InputDecoration(
                  hintText: 'Ej. 1712345678',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.badge, color: Colors.grey),
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
              const SizedBox(height: 24),

              // Nombre del Representante
              Text(
                'NOMBRES DEL REPRESENTANTE',
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _parentNameController,
                style: GoogleFonts.publicSans(),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Ej. Juan Pérez',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.supervisor_account, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 24),

              // Correo Electrónico
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
                controller: _parentEmailController,
                style: GoogleFonts.publicSans(),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'representante@ejemplo.com',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.email, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 24),

              // Nombre del Estudiante
              Text(
                'NOMBRES DEL ESTUDIANTE',
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
              const SizedBox(height: 24),

              // Grado / Curso
              Text(
                'GRADO / CURSO',
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedGrade,
                decoration: InputDecoration(
                  hintText: 'Seleccione un grado',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.school, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _selectedGrade = val),
              ),
              const SizedBox(height: 24),

              // Tipo de Recorrido
              Text(
                'TIPO DE RECORRIDO / SERVICIO',
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedServiceType,
                decoration: InputDecoration(
                  hintText: 'Seleccione el servicio',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.sync_alt, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                items: _serviceTypes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedServiceType = val),
              ),
              const SizedBox(height: 24),

              // Fijar Parada en Mapa
              Text(
                'UBICACIÓN DE LA PARADA',
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    final LatLng? result = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const ParentMapPickerScreen())
                    );
                    if (result != null) {
                      setState(() {
                        _selectedLocation = result;
                        _errorMessage = null; // Quitar error si lo había
                      });
                    }
                  },
                  icon: Icon(
                    _selectedLocation != null ? Icons.check_circle : Icons.add_location_alt,
                    color: _selectedLocation != null ? Colors.white : AppColors.primaryContainer,
                  ),
                  label: Text(
                    _selectedLocation != null ? 'PARADA FIJADA EN MAPA' : 'FIJAR EN MAPA',
                    style: GoogleFonts.publicSans(
                      fontWeight: FontWeight.bold, 
                      color: _selectedLocation != null ? Colors.white : AppColors.primaryContainer,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedLocation != null ? Colors.green : AppColors.surface,
                    side: _selectedLocation != null ? null : const BorderSide(color: AppColors.outline, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: _selectedLocation != null ? 4 : 0,
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
                      readOnly: widget.fixedUnitCode != null,
                      style: GoogleFonts.publicSans(),
                      onChanged: (val) {
                        final normalized = val.toUpperCase();
                        if (normalized != val) {
                          _unitCodeController.value = TextEditingValue(
                            text: normalized,
                            selection: TextSelection.collapsed(offset: normalized.length),
                          );
                        }
                        setState(() {
                          _errorMessage = null;
                          _schoolName = null;
                        });
                        if (normalized.length >= 3) _validateUnit(normalized);
                      },
                      decoration: InputDecoration(
                        hintText: 'Ej. UNIDAD-42',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.directions_bus, color: Colors.grey),
                        suffixIcon: _isValidatingUnit ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
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
                            color: (_isScanning ? Colors.red : AppColors.primaryContainer).withValues(alpha: 0.3),
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
              
              if (_schoolName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Vinculando a: $_schoolName',
                          style: GoogleFonts.publicSans(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
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
                        child: Icon(Icons.crop_free, size: 100, color: Colors.white.withValues(alpha: 0.5)),
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
                        ? Colors.green.withValues(alpha: 0.1) 
                        : Colors.red.withValues(alpha: 0.1),
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
