import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/services/parent_school_link_service.dart';

class ParentOnboardingScreen extends ConsumerStatefulWidget {
  const ParentOnboardingScreen({super.key});

  @override
  ConsumerState<ParentOnboardingScreen> createState() =>
      _ParentOnboardingScreenState();
}

class _ParentOnboardingScreenState extends ConsumerState<ParentOnboardingScreen> {
  final _codeController = TextEditingController();
  final _cedulaController = TextEditingController();
  String? _error;
  String? _success;
  bool _linking = false;

  @override
  void dispose() {
    _codeController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    final cedula = _cedulaController.text.trim();
    if (code.isEmpty || cedula.isEmpty) {
      setState(() => _error = 'Completa el codigo del colegio y tu cedula.');
      return;
    }

    setState(() {
      _linking = true;
      _error = null;
      _success = null;
    });

    try {
      final result = await linkParentSchool(
        ref,
        code,
        cedulaPadre: cedula,
      );

      if (!mounted) return;
      setState(() {
        _success = result.claimedCount > 0
            ? 'Colegio vinculado. Se encontraron ${result.claimedCount} estudiante(s).'
            : 'Colegio vinculado correctamente.';
      });

      await Future<void>.delayed(const Duration(milliseconds: 900));
    } catch (e) {
      if (mounted) {
        setState(() => _error = friendlyLinkError(e));
      }
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF004782),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_bus, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'RutaSegura',
                        style: GoogleFonts.publicSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Vincula tu colegio',
                style: GoogleFonts.publicSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF004782),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa el codigo que te dio la unidad escolar y tu cedula para ver el recorrido del bus de tus hijos.',
                style: GoogleFonts.publicSans(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Codigo del colegio',
                  hintText: 'Ej. CAD31',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cedulaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cedula del representante',
                  hintText: 'Misma cedula del registro escolar',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              if (_success != null) ...[
                const SizedBox(height: 12),
                Text(
                  _success!,
                  style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _linking ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004782),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _linking
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'VINCULAR Y CONTINUAR',
                          style: GoogleFonts.publicSans(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}