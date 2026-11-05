import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/license_service.dart';

class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key});

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  final _keyController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingresa una clave de licencia.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(licenseProvider.notifier).activateKey(key);

    setState(() {
      _isLoading = false;
      if (!success) {
        _errorMessage = ref.read(licenseProvider.notifier).lastError ?? 'No se pudo activar la clave.';
      } else {
        _keyController.clear();
      }
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('¡Licencia PRO activada con éxito!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final license = ref.watch(licenseProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KeyBlue PRO', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner de estado
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: license.active
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [cs.primary, const Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (license.active ? Colors.green : cs.primary).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  license.active ? Icons.verified : Icons.workspace_premium,
                  size: 56,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  license.active ? 'ESTADO: PRO ACTIVO' : 'MODALIDAD FREE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  license.active
                      ? _licenseTypeTitle(license.type)
                      : 'Desbloquea todo el potencial de KeyBlue',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (license.active) ...[
            // Detalles de la licencia activa
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalles de tu Licencia',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow('Clave:', license.key ?? 'N/A'),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      'Tipo:',
                      _licenseTypeTitle(license.type),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      'Vencimiento:',
                      license.expiresAt != null
                          ? '${license.expiresAt!.day}/${license.expiresAt!.month}/${license.expiresAt!.year}'
                          : 'De por vida (Permanente)',
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () async {
                        await ref.read(licenseProvider.notifier).deactivate();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Licencia desactivada.')),
                          );
                        }
                      },
                      child: const Text('Desactivar esta licencia'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Beneficios PRO
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Beneficios Exclusivos PRO',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureItem(Icons.palette, 'Todos los 15 temas premium desbloqueados'),
                    _buildFeatureItem(Icons.tune, 'Personalización individual por tecla sin restricciones'),
                    _buildFeatureItem(Icons.folder_special, 'Perfiles ilimitados guardados en tu dispositivo'),
                    _buildFeatureItem(Icons.cloud_off, 'Funciona 100% offline con licencia verificable'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Formulario de activación
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Activar con Clave (KEY)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Introduce la clave KEYF-XXXX-XXXX-XXXX provista por el administrador.',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _keyController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'KEYF-XXXX-XXXX-XXXX',
                        errorText: _errorMessage,
                        prefixIcon: const Icon(Icons.key),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isLoading ? null : _activate,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Activar Licencia PRO'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  String _licenseTypeTitle(LicenseType type) {
    switch (type) {
      case LicenseType.proPermanent:
        return 'PRO Permanente';
      case LicenseType.pro30Days:
        return 'PRO 30 Días';
      case LicenseType.pro90Days:
        return 'PRO 90 Días';
      case LicenseType.proAnnual:
        return 'PRO Anual';
      case LicenseType.free:
        return 'Gratuita';
    }
  }
}

