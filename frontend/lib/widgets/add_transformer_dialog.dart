import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transformer_provider.dart';

import '../models/transformer.dart';

class AddTransformerDialog extends StatefulWidget {
  final Transformer? transformer;

  const AddTransformerDialog({Key? key, this.transformer}) : super(key: key);

  @override
  _AddTransformerDialogState createState() => _AddTransformerDialogState();
}

class _AddTransformerDialogState extends State<AddTransformerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _locationController;
  late TextEditingController _voltageController;
  late TextEditingController _currentController;
  int _fuseCount = 3;

  @override
  void initState() {
    super.initState();
    final t = widget.transformer;
    _idController = TextEditingController(text: t?.transformerId ?? '');
    _locationController = TextEditingController(text: t?.location ?? '');
    _voltageController = TextEditingController(text: t?.voltageThreshold.toString() ?? '');
    _currentController = TextEditingController(text: t?.currentThreshold.toString() ?? '');
    _fuseCount = t?.fuses.length ?? 3;
  }

  @override
  void dispose() {
    _idController.dispose();
    _locationController.dispose();
    _voltageController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transformer != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Transformer' : 'Add New Transformer'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(labelText: 'Transformer ID (e.g. TX-001)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _voltageController,
                decoration: InputDecoration(labelText: 'Voltage Threshold (V)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _currentController,
                decoration: InputDecoration(labelText: 'Current Threshold (A)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Number of Fuses: $_fuseCount'),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () => setState(() {
                      if (_fuseCount > 1) _fuseCount--;
                    }),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () => setState(() => _fuseCount++),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final fuses = List.generate(
                _fuseCount,
                (i) => {'fuseId': 'F${i + 1}', 'status': 'Healthy'}
              );
              
              final data = {
                'transformerId': _idController.text,
                'location': _locationController.text,
                'voltageThreshold': double.tryParse(_voltageController.text) ?? 240.0,
                'currentThreshold': double.tryParse(_currentController.text) ?? 100.0,
                'fuses': fuses
              };

              final provider = Provider.of<TransformerProvider>(context, listen: false);
              bool success;
              if (isEditing) {
                success = await provider.updateTransformer(widget.transformer!.id, data);
              } else {
                success = await provider.addTransformer(data);
              }
              
              if (success) {
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider.error ?? 'Failed to save'))
                );
              }
            }
          },
          child: Text('Save'),
        )
      ],
    );
  }
}
