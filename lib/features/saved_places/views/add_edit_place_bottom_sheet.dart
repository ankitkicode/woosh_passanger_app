import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_place_model.dart';
import '../view_models/saved_places_view_model.dart';

class AddEditPlaceBottomSheet extends ConsumerStatefulWidget {
  final SavedPlace? place;
  final String defaultType;

  const AddEditPlaceBottomSheet({
    super.key,
    this.place,
    this.defaultType = 'other',
  });

  @override
  ConsumerState<AddEditPlaceBottomSheet> createState() =>
      _AddEditPlaceBottomSheetState();
}

class _AddEditPlaceBottomSheetState
    extends ConsumerState<AddEditPlaceBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _addressController;
  late String _selectedType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.place?.title ?? '',
    );
    _addressController = TextEditingController(
      text: widget.place?.address ?? '',
    );
    _selectedType = widget.place?.type ?? widget.defaultType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final address = _addressController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address is required')),
      );
      return;
    }

    if (_selectedType == 'other' && title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required for custom places')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final viewModel = ref.read(savedPlacesProvider.notifier);
    bool success = false;

    if (widget.place != null) {
      // Update
      success = await viewModel.updateSavedPlace(
        widget.place!.id,
        {
          'title': _selectedType == 'other' ? title : _selectedType.toUpperCase(),
          'address': address,
          'type': _selectedType,
          'latitude': widget.place!.latitude,
          'longitude': widget.place!.longitude,
        },
      );
    } else {
      // Create
      final newPlace = SavedPlace(
        id: '',
        user: '', // Handled by backend usually
        type: _selectedType,
        title: _selectedType == 'other' ? title : _selectedType.toUpperCase(),
        address: address,
        latitude: 0.0,
        longitude: 0.0,
      );
      success = await viewModel.addSavedPlace(newPlace);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save place')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If it's a specific type (Home/Work), we might not allow changing the type
    final isFixedType =
        widget.defaultType == 'home' || widget.defaultType == 'work';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.place == null ? 'Add Place' : 'Edit Place',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isFixedType) ...[
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Place Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'home', child: Text('Home')),
                DropdownMenuItem(value: 'work', child: Text('Work')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          if (_selectedType == 'other') ...[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title (e.g., Gym, College)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD40B7E),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
