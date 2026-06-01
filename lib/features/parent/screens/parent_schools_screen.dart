import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/providers/route_provider.dart';
import 'add_student_screen.dart';
import 'parent_dashboard_screen.dart';

class ParentSchoolsScreen extends ConsumerStatefulWidget {
  const ParentSchoolsScreen({super.key, this.selectOnly = false});

  final bool selectOnly;

  @override
  ConsumerState<ParentSchoolsScreen> createState() => _ParentSchoolsScreenState();
}

class _ParentSchoolsScreenState extends ConsumerState<ParentSchoolsScreen> {
  final _codeController = TextEditingController();
  String? _error;
  bool _linking = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _linkSchool() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _linking = true;
      _error = null;
    });
    try {
      await linkParentSchool(ref, code);
      _codeController.clear();
      if (!mounted) return;
      if (widget.selectOnly) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Future<void> _openSchool(String code) async {
    await setParentActiveUnit(ref, code);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linkedAsync = ref.watch(linkedUnitCodesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Mis colegios',
          style: GoogleFonts.publicSans(fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFF004782),
        foregroundColor: Colors.white,
      ),
      body: linkedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (codes) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Vincula el codigo que te dio el colegio. Cada codigo tiene su propio panel y mapa.',
                style: GoogleFonts.publicSans(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(height: 20),
              if (codes.isNotEmpty) ...[
                Text(
                  'COLEGIOS VINCULADOS',
                  style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                ...codes.map((code) {
                  return FutureBuilder<Map<String, dynamic>?>(
                    future: ref.read(companyByUnitProvider(code).future),
                    builder: (context, snap) {
                      final name = snap.data?['name'] as String? ?? code;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF004782),
                            child: Icon(Icons.school, color: Colors.white),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Codigo: $code'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openSchool(code),
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 24),
              ],
              Text(
                'VINCULAR NUEVO COLEGIO',
                style: GoogleFonts.publicSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
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
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _linking ? null : _linkSchool,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004782),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _linking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('VINCULAR COLEGIO'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final active = await ref.read(activeUnitCodeProvider.future);
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddStudentScreen(fixedUnitCode: active),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Anadir estudiante al colegio activo'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
