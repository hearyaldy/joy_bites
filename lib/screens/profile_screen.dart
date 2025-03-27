import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import 'package:joy_bites/providers/user_provider.dart'; // Import the provider.
import 'entry_screen.dart'; // Import your fallback or home screen if needed.

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _selectedAvatar;
  bool _isUpdating = false;
  String? _errorMessage;

  // List of preset avatar asset paths.
  final List<String> _avatarUrls = [
    'assets/avatars/avatar_1.png',
    'assets/avatars/avatar_2.png',
    'assets/avatars/avatar_3.png',
    'assets/avatars/avatar_4.png',
    'assets/avatars/avatar_5.png',
    'assets/avatars/avatar_6.png',
  ];

  // For picking images from the device.
  final ImagePicker _picker = ImagePicker();

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> _loadUserData() async {
    final user = currentUser;
    if (user != null) {
      _nameController.text = user.userMetadata?['full_name'] ?? '';
      _selectedAvatar = user.userMetadata?['avatar_url'];
      setState(() {});
    }
  }

  // If no avatar is selected, pick a random one from the preset list.
  String _getRandomAvatar() {
    final random = Random();
    int index = random.nextInt(_avatarUrls.length);
    return _avatarUrls[index];
  }

  // Pick an image from the gallery and upload it to Supabase Storage.
  Future<void> _pickAndUploadAvatar() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return; // User canceled image selection.

    final file = File(pickedFile.path);
    final fileExt = pickedFile.path.split('.').last;
    final userId = currentUser?.id ?? 'guest';
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    try {
      await _supabase.storage.from('avatars').upload(fileName, file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return;
    }

    // Retrieve the public URL directly.
    final publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
    if (publicUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to retrieve public URL for image')),
      );
      return;
    }

    setState(() {
      _selectedAvatar = publicUrl;
    });
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });
    try {
      final avatar = _selectedAvatar ?? _getRandomAvatar();
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': _nameController.text.trim(),
            'avatar_url': avatar,
          },
        ),
      );
      if (response.user != null) {
        // Refresh session and update global user data.
        await _supabase.auth.refreshSession();
        final updatedUser = _supabase.auth.currentUser;
        Provider.of<UserProvider>(context, listen: false).updateUser(updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        // Pop the screen or navigate to your entry/home screen.
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EntryScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = "Profile update failed: No user returned.";
        });
      }
    } catch (e, stackTrace) {
      print("Error updating profile: $e");
      print(stackTrace);
      setState(() {
        _errorMessage = "Error updating profile: ${e.toString()}";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Build a grid of preset avatar images.
  Widget _buildAvatarGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _avatarUrls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final assetPath = _avatarUrls[index];
        bool isSelected = assetPath == _selectedAvatar;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAvatar = assetPath;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.deepOrange : Colors.transparent,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, color: Colors.white),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Display a preview of the selected avatar.
  Widget _displaySelectedAvatar() {
    if (_selectedAvatar == null) return const SizedBox();
    if (_selectedAvatar!.startsWith('http')) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(_selectedAvatar!),
      );
    } else {
      return CircleAvatar(
        radius: 50,
        backgroundImage: AssetImage(_selectedAvatar!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar; the screen is displayed within your app's navigation.
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isUpdating
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _displaySelectedAvatar()),
                    const SizedBox(height: 16),
                    const Text("Display Name:", style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: "Enter your display name",
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Select an Avatar:", style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    _buildAvatarGrid(),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _pickAndUploadAvatar,
                        child: const Text("Choose Custom Photo"),
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Save Profile", style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
