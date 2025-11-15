import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userModel;

  const EditProfileScreen({
    super.key,
    required this.userModel,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  final _dataService = DataService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  bool _isSaving = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userModel.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Lower quality for Base64 compatibility
        maxWidth: 500, // Smaller size for Base64
        maxHeight: 500,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Convert image to Base64 string (for Supabase Storage fallback)
  /// Uses compute to avoid blocking main thread
  Future<String?> _imageToBase64(File imageFile) async {
    try {
      // Read file asynchronously to avoid blocking
      final bytes = await imageFile.readAsBytes().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Image read timeout');
        },
      );
      
      // Compress more if needed (max 200KB for Base64 storage limit)
      if (bytes.length > 200 * 1024) {
        // If image is too large, show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large. Please choose a smaller image.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }
      
      // Encode in a separate isolate to avoid blocking UI
      return await Future(() => base64Encode(bytes));
    } catch (e) {
      print('Error converting image to Base64: $e');
      return null;
    }
  }

  /// Upload image - tries Supabase Storage first, falls back to Base64
  Future<String?> _uploadImage() async {
    if (_selectedImage == null) {
      return null; // Return existing photoURL if no new image selected
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    // Try Supabase Storage first
    try {
      final publicUrl = await _storageService.uploadImage(
        imageFile: _selectedImage!,
        userId: user.id,
      );

      if (publicUrl != null) {
        return publicUrl;
      } else {
        // Upload returned null - check console for error details
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload to Supabase failed. Using fallback method...'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Supabase Storage failed - fallback to Base64
      print('❌ Exception during Supabase upload: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    // Fallback: Convert to Base64 and return as data URL
    // Only show message if Supabase is configured (meaning it should work)
    final base64String = await _imageToBase64(_selectedImage!);
    if (base64String != null) {
      return 'data:image/jpeg;base64,$base64String';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final displayName = _nameController.text.trim();
      
      // Upload image if selected
      String? photoURL = widget.userModel.photoURL; // Keep existing if no new image
      if (_selectedImage != null) {
        photoURL = await _uploadImage() ?? widget.userModel.photoURL;
      }

      // Update Supabase Auth profile
      await _authService.updateProfile(
        displayName: displayName.isEmpty ? null : displayName,
        photoURL: photoURL,
      );

      // Update Supabase database
      final user = _authService.currentUser;
      if (user != null) {
        final updateData = <String, dynamic>{
          'displayName': displayName.isEmpty ? null : displayName,
          'updatedAt': DateTime.now(),
        };
        
        // Only update photoURL if we have a new one
        if (photoURL != null) {
          updateData['photoURL'] = photoURL;
        }
        
        // Remove null values
        updateData.removeWhere((key, value) => value == null);

        await _dataService.updateUserData(
          userId: user.id,
          updateData: updateData,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which image to display
    Widget? avatarChild;
    ImageProvider? backgroundImage;

    if (_selectedImage != null) {
      // Show selected local image
      backgroundImage = FileImage(_selectedImage!);
    } else if (widget.userModel.photoURL != null) {
      // Show existing network image
      backgroundImage = NetworkImage(widget.userModel.photoURL!);
    } else {
      // Show initial letter
      avatarChild = Text(
        _nameController.text.isNotEmpty
            ? _nameController.text[0].toUpperCase()
            : widget.userModel.email?[0].toUpperCase() ?? 'U',
        style: const TextStyle(
          fontSize: 40,
          color: Colors.white,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Profile Picture Preview
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue,
                      backgroundImage: backgroundImage,
                      onBackgroundImageError: backgroundImage != null
                          ? (exception, stackTrace) {
                              // Handle image load error - show initial letter instead
                              setState(() {
                                _selectedImage = null;
                              });
                            }
                          : null,
                      child: avatarChild,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18),
                          color: Colors.white,
                          onPressed: _isSaving ? null : _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _isSaving ? null : _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose from Gallery'),
                ),
              ),
              const SizedBox(height: 32),
              // Display Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value != null && value.trim().length > 50) {
                    return 'Name must be less than 50 characters';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // Update avatar preview
                },
              ),
              const SizedBox(height: 32),
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Email cannot be changed here. Contact support if you need to change your email.',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              // Cancel Button
              OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
