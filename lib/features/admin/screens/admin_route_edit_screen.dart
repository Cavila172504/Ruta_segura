import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/providers/map_provider.dart';

class AdminRouteEditScreen extends ConsumerStatefulWidget {
  const AdminRouteEditScreen({super.key});

  @override
  ConsumerState<AdminRouteEditScreen> createState() => _AdminRouteEditScreenState();
}

class _AdminRouteEditScreenState extends ConsumerState<AdminRouteEditScreen> {
  final Color _primary = const Color(0xFF3B309E);
  final Color _primaryContainer = const Color(0xFF534AB7);
  final Color _surface = const Color(0xFFFCF8FF);
  final Color _onSurface = const Color(0xFF1C1B22);
  final Color _surfaceContainerLowest = const Color(0xFFFFFFFF);

  final List<Map<String, dynamic>> _students = [
    {'name': 'Mateo Sebastian Ruiz', 'address': 'Calle Lago Zurich 245, Edif. A'},
    {'name': 'Lucía Fernanda Torres', 'address': 'Av. Horacio 1205, Int 402'},
    {'name': 'Iker Santiago Paredes', 'address': 'Privada de los Pinos 14, San Ángel'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: BackButton(color: _primary),
        title: Text('RutaSegura Admin', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: _onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GESTIÓN DE LOGÍSTICA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _primary, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text('Configurar Nueva Ruta', style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: _onSurface)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 400,
                      child: Text('Define el trayecto, asigna conductores y organiza el orden de recogida de los estudiantes de manera eficiente.', style: GoogleFonts.inter(color: Colors.grey.shade700)),
                    ),
                  ],
                ),
                // Actions (desktop)
                if (MediaQuery.of(context).size.width > 800)
                  Row(
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.grey.shade300, width: 2))), child: Text('Cancelar', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                      const SizedBox(width: 12),
                      ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: _primary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 8), child: Text('Guardar ruta', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white))),
                    ],
                  )
              ],
            ),
            const SizedBox(height: 32),

            // Main Content
            LayoutBuilder(
              builder: (context, constraints) {
                bool isDesktop = constraints.maxWidth > 800;
                
                Widget leftCol = Column(
                  children: [
                    _buildFormCard(),
                    const SizedBox(height: 24),
                    _buildSummaryCard(),
                  ],
                );
                
                Widget rightCol = Column(
                  children: [
                    _buildMapCard(),
                    const SizedBox(height: 24),
                    _buildStudentsCard(),
                  ],
                );

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: leftCol),
                      const SizedBox(width: 24),
                      Expanded(flex: 8, child: rightCol),
                    ],
                  );
                } else {
                  return Column(children: [leftCol, const SizedBox(height: 24), rightCol]);
                }
              }
            )
          ],
        ),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 800 ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(backgroundColor: const Color(0xFFF0ECF6), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text('Cancelar', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _primary)))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: _primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text('Guardar ruta', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)))),
            ],
          ),
        ),
      ) : null,
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _surfaceContainerLowest, borderRadius: BorderRadius.circular(32), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DETALLES BÁSICOS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _primary, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          _buildInputLabel('Nombre de la ruta'),
          _buildTextField('Ej. Norte - Cumbres de Santa Fe'),
          const SizedBox(height: 16),
          _buildInputLabel('Conductor Asignado'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFFEBE6F0), borderRadius: BorderRadius.circular(16)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'Seleccionar conductor...',
                isExpanded: true,
                items: ['Seleccionar conductor...', 'Ricardo Mendoza - Licencia Federal A'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter()))).toList(),
                onChanged: (_) {},
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInputLabel('Hora de inicio'),
          _buildTextField('07:00', icon: Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)));
  Widget _buildTextField(String hint, {IconData? icon}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFEBE6F0), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: icon != null ? Icon(icon, color: Colors.grey.shade600) : null,
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFF0ECF6), borderRadius: BorderRadius.circular(32)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info, color: _primary),
              const SizedBox(width: 8),
              Text('Resumen de Trayecto', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _primaryContainer)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Estudiantes:', '12 registrados'),
          const SizedBox(height: 12),
          _buildSummaryRow('Tiempo estimado:', '45 mins'),
          const SizedBox(height: 12),
          _buildSummaryRow('Distancia:', '18.4 km'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 14)),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: _surfaceContainerLowest, 
        borderRadius: BorderRadius.circular(32), 
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Consumer(
              builder: (context, ref, _) {
                final locationAsync = ref.watch(currentLocationStreamProvider);
                
                return locationAsync.when(
                  data: (position) {
                    final latLng = LatLng(position.latitude, position.longitude);
                    return GoogleMap(
                      initialCameraPosition: CameraPosition(target: latLng, zoom: 14),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (controller) {},
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => GoogleMap(
                    initialCameraPosition: const CameraPosition(target: defaultInitialLocation, zoom: 12),
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 16, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: _primary, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('MAPA INTERACTIVO ACTIVO', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _primary)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24, right: 24,
            child: Column(
              children: [
                _mapBtn(Icons.add), const SizedBox(height: 8),
                _mapBtn(Icons.remove), const SizedBox(height: 8),
                _mapBtn(Icons.my_location),
              ],
            ),
          )
        ],
      ),
    );
  }
  
  Widget _mapBtn(IconData icon) => Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]), child: Icon(icon));

  Widget _buildStudentsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _surfaceContainerLowest, borderRadius: BorderRadius.circular(32), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ORDEN DE RECOGIDA', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _primary, letterSpacing: 1.5)),
              TextButton(onPressed: () {}, style: TextButton.styleFrom(backgroundColor: _primary.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text('Añadir Estudiante', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _primary))),
            ],
          ),
          const SizedBox(height: 16),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _students.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _students.removeAt(oldIndex);
                _students.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final student = _students[index];
              return Container(
                key: ValueKey(student['name']),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF6F2FC), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(width: 32, height: 32, decoration: BoxDecoration(color: _primary, shape: BoxShape.circle), alignment: Alignment.center, child: Text('${index + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student['name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _onSurface)),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(student['address'], style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const Icon(Icons.drag_indicator, color: Colors.grey),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
