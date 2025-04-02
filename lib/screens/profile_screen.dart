import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/theme_toggle.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  File? _profileImage;
  bool _isEditing = false;
  bool _isLoading = false;
  Map<String, dynamic> profileData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare profile data
      profileData['name'] = _nameController.text;
      profileData['email'] = _emailController.text;
      
      // Note: office_id is added in the dropdown onChanged handler

      // Update profile
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.updateProfile(profileData, _profileImage);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() {
          _isEditing = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update profile')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveProfile,
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (ctx, authProvider, _) {
          final user = authProvider.user;
          
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!) as ImageProvider
                              : (user.profilePicture != null
                                  ? NetworkImage('http://localhost:8000/storage/${user.profilePicture}')
                                  : const AssetImage('assets/logo.png')) as ImageProvider,
                        ),
                        if (_isEditing)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // User Info
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Theme Toggle
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const ThemeToggle(),
                  const SizedBox(height: 8),
                  const Divider(),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Theme Toggle
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const ThemeToggle(),
                  const SizedBox(height: 8),
                  const Divider(),
                  
                  // Office Info (Editable when in edit mode)
                  _isEditing
                      ? FutureBuilder<List<Map<String, dynamic>>>(
                          future: Provider.of<AuthProvider>(context, listen: false).getOffices(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            final offices = snapshot.data ?? [];
                            String? selectedOfficeId = user.officeId?.toString();
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  value: selectedOfficeId,
                                  decoration: const InputDecoration(
                                    labelText: 'Office',
                                    border: OutlineInputBorder(),
                                  ),
                                  hint: const Text('Select an office'),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: '',
                                      child: Text('No Office'),
                                    ),
                                    ...offices.map((office) => DropdownMenuItem<String>(
                                          value: office['id'].toString(),
                                          child: Text(office['name']),
                                        )),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedOfficeId = value;
                                    });
                                    // Add office_id to profile data
                                    if (value != null && value.isNotEmpty) {
                                      profileData['office_id'] = value;
                                    } else {
                                      profileData['office_id'] = null;
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text('Role: ${_getUserRole(user.type)}',
                                    style: Theme.of(context).textTheme.titleMedium),
                              ],
                            );
                          },
                        )
                      : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Office: ${user.officeName ?? 'Not assigned'}',
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('Role: ${_getUserRole(user.type)}',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        ),
                  
                  if (_isEditing && _isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 20.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  String _getUserRole(int? type) {
    switch (type) {
      case 0:
        return 'User';
      case 1:
        return 'Staff';
      case 2:
        return 'Admin';
      case 3:
        return 'Super Admin';
      default:
        return 'Unknown';
    }
  }
}