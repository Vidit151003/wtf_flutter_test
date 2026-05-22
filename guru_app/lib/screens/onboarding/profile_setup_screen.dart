import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../../providers/auth_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'DK');
  String? _selectedTrainerId = 'trainer_001';
  bool _isLoading = false;

  static const List<Map<String, String>> _trainers = [
    {'id': 'trainer_001', 'name': 'Aarav'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTrainerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a trainer.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.createDKProfile(_selectedTrainerId!);
      await authProvider.setOnboarded();
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kSpacing24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kGuruPrimary, kGuruPrimaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kGuruPrimary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: kSpacing32),

                Text(
                  "What's your name?",
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: kSpacing8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.validateName(v ?? ''),
                ),
                const SizedBox(height: kSpacing24),

                Text(
                  'Choose Your Trainer',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: kSpacing8),
                DropdownButtonFormField<String>(
                  value: _selectedTrainerId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.sports_outlined),
                  ),
                  items: _trainers.map((t) {
                    return DropdownMenuItem<String>(
                      value: t['id'],
                      child: Text(t['name']!),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedTrainerId = v),
                  validator: (v) =>
                      v == null ? 'Please select a trainer.' : null,
                ),
                const SizedBox(height: kSpacing32),

                // Info card
                Container(
                  padding: const EdgeInsets.all(kSpacing16),
                  decoration: BoxDecoration(
                    color: kGuruSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kGuruNeutral300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: kGuruPrimary, size: 20),
                      const SizedBox(width: kSpacing12),
                      Expanded(
                        child: Text(
                          'Aarav is your dedicated trainer who will guide your fitness journey.',
                          style: textTheme.bodySmall?.copyWith(
                            color: kGuruNeutral700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: kSpacing32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGuruPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Let's Go"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
