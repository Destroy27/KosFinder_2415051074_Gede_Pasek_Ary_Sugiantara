import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/messages.dart';
import '../models/kos.dart';
import '../services/kos_service.dart';
import '../theme/app_theme.dart';

class KosFormPage extends StatefulWidget {
  const KosFormPage({super.key, this.kos});

  /// Null berarti tambah data baru, selain itu berarti mengubah data.
  final Kos? kos;

  @override
  State<KosFormPage> createState() => _KosFormPageState();
}

class _KosFormPageState extends State<KosFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final KosService _service = KosService();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  bool _saving = false;

  bool get _isEdit => widget.kos != null;

  @override
  void initState() {
    super.initState();
    final Kos? kos = widget.kos;
    _nameController = TextEditingController(text: kos?.name ?? '');
    _addressController = TextEditingController(text: kos?.address ?? '');
    _priceController = TextEditingController(
      text: kos == null || kos.price == 0 ? '' : '${kos.price}',
    );
    _descriptionController = TextEditingController(
      text: kos?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final int price = int.tryParse(_priceController.text.trim()) ?? 0;

      if (_isEdit) {
        final bool updated = await _service.update(
          widget.kos!.id,
          <String, dynamic>{
            'name': _nameController.text.trim(),
            'address': _addressController.text.trim(),
            'price': price,
            'description': _descriptionController.text.trim(),
          },
        );
        if (!mounted) return;
        if (!updated) {
          _showMessage('Perubahan ditolak: data ini bukan milikmu (RLS).');
          return;
        }
      } else {
        await _service.add(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          price: price,
          description: _descriptionController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(friendlyDatabaseMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Ubah Kos' : 'Tambah Kos')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: <Widget>[
            const Text(
              'Data kos hanya bisa diubah atau dihapus oleh pemiliknya. '
              'Aturan ini dijaga oleh Row Level Security, bukan hanya oleh tampilan.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama kos'),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama kos wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                hintText: 'Jl. Udayana No. 12, Singaraja',
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Alamat wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Harga per bulan',
                prefixText: 'Rp ',
                hintText: '750000',
              ),
              validator: (String? value) {
                final int price = int.tryParse(value?.trim() ?? '') ?? 0;
                if (price <= 0) return 'Harga harus lebih dari 0';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                hintText: 'Fasilitas, jarak ke kampus, aturan kos, dsb.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_isEdit ? 'Simpan perubahan' : 'Simpan kos'),
            ),
          ],
        ),
      ),
    );
  }
}
