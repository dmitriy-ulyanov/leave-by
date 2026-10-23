import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/providers/id_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../application/saved_trip_form_notifier.dart';
import '../domain/saved_trip.dart';

class SavedTripFormScreen extends ConsumerStatefulWidget {
  const SavedTripFormScreen({super.key, this.initial});

  final SavedTrip? initial;

  @override
  ConsumerState<SavedTripFormScreen> createState() => _SavedTripFormScreenState();
}

class _SavedTripFormScreenState extends ConsumerState<SavedTripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _originController;
  late final TextEditingController _destinationController;
  late final TextEditingController _arriveByController;
  late final TextEditingController _noteController;

  bool get _isEdit => widget.initial != null && widget.initial!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _originController = TextEditingController(text: initial?.origin ?? '');
    _destinationController = TextEditingController(text: initial?.destination ?? '');
    _arriveByController = TextEditingController(text: initial == null ? '' : formatTime(initial.arriveBy));
    _noteController = TextEditingController(text: initial?.note ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _arriveByController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool _sameTime(DateTime a, DateTime b) => a.hour == b.hour && a.minute == b.minute;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final now = ref.read(clockProvider)();
    final arriveBy = Validators.parseTime(_arriveByController.text, now)!;
    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();
    final initial = widget.initial;
    final unchanged = initial != null &&
        initial.origin == origin &&
        initial.destination == destination &&
        _sameTime(initial.arriveBy, arriveBy);
    final kept = unchanged ? initial : null;
    final trip = SavedTrip(
      id: _isEdit ? initial!.id : ref.read(idGeneratorProvider)(),
      title: _titleController.text.trim(),
      origin: origin,
      destination: destination,
      arriveBy: arriveBy,
      optionLabel: kept?.optionLabel ?? '',
      departAt: kept?.departAt,
      note: _noteController.text.trim(),
      createdAt: _isEdit ? initial!.createdAt : now,
    );
    final success = await ref.read(savedTripFormProvider.notifier).submit(trip);
    if (!success || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Perubahan tersimpan.' : 'Perjalanan tersimpan.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(savedTripFormProvider);
    ref.listen<SavedTripFormState>(savedTripFormProvider, (previous, next) {
      final message = next.errorMessage;
      if (message != null && previous?.errorMessage != message) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    });
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Ubah Perjalanan' : 'Perjalanan Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('tripTitleField'),
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul'),
                validator: Validators.title,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('tripOriginField'),
                controller: _originController,
                decoration: const InputDecoration(labelText: 'Asal'),
                validator: (value) => Validators.requiredText(value, 'Asal wajib diisi'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('tripDestinationField'),
                controller: _destinationController,
                decoration: const InputDecoration(labelText: 'Tujuan'),
                validator: (value) => Validators.tripDestination(value, _originController.text),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('tripArriveByField'),
                controller: _arriveByController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(labelText: 'Jam tiba (HH:mm)'),
                validator: Validators.timeFormat,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('tripNoteField'),
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                validator: Validators.note,
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('tripSubmitButton'),
                onPressed: form.isSubmitting ? null : _submit,
                child: form.isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Perjalanan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
