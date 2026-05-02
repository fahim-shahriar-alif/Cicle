import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/image_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  final _imageService = ImageService();
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  String? _displayName;
  String? _email;
  String? _avatarUrl;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Get user metadata
      final metadata = user.userMetadata;
      
      // Get profile from database
      final response = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _email = user.email;
        _displayName = metadata?['display_name'] ?? response['display_name'];
        _avatarUrl = response['avatar_url'];
        _status = response['status'];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editDisplayName() async {
    final controller = TextEditingController(text: _displayName);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _displayName) {
      await _updateDisplayName(newName);
    }
  }

  Future<void> _updateDisplayName(String newName) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Update in database
      await supabase
          .from('users')
          .update({'display_name': newName})
          .eq('id', user.id);

      // Update auth metadata
      await supabase.auth.updateUser(
        UserAttributes(data: {'display_name': newName}),
      );

      setState(() => _displayName = newName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Display name updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating name: $e')),
        );
      }
    }
  }

  Future<void> _changeStatus() async {
    final statuses = [
      '💼 At Work',
      '📚 Studying',
      '🍕 Hungry',
      '🏠 At Home',
      '🚗 Driving',
      '😴 Sleeping',
      '🎮 Gaming',
      '🎵 Listening to Music',
      '🏃 Exercising',
      '✨ Available',
    ];

    final selectedStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Status'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              final status = statuses[index];
              return ListTile(
                title: Text(status),
                selected: status == _status,
                onTap: () => Navigator.pop(context, status),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedStatus != null) {
      await _updateStatus(selectedStatus);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase
          .from('users')
          .update({'status': newStatus})
          .eq('id', user.id);

      setState(() => _status = newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Future<void> _uploadAvatar() async {
    try {
      // Show image source selection
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      setState(() => _isUploadingAvatar = true);

      // Pick image
      final imageFile = await _imageService.pickImage(source: source);
      if (imageFile == null) {
        setState(() => _isUploadingAvatar = false);
        return;
      }

      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Delete old avatar if exists
      if (_avatarUrl != null) {
        await _imageService.deleteAvatar(_avatarUrl!);
      }

      // Upload new avatar
      final avatarUrl = await _imageService.uploadAvatar(imageFile, user.id);

      // Update database
      await supabase
          .from('users')
          .update({'avatar_url': avatarUrl})
          .eq('id', user.id);

      setState(() {
        _avatarUrl = avatarUrl;
        _isUploadingAvatar = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated!')),
        );
      }
    } catch (e) {
      setState(() => _isUploadingAvatar = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading avatar: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.purple.shade100,
                    backgroundImage: _avatarUrl != null
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null
                        ? Text(
                            _displayName?.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          )
                        : null,
                  ),
                  if (_isUploadingAvatar)
                    Positioned.fill(
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.black54,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.purple,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20),
                        color: Colors.white,
                        onPressed: _isUploadingAvatar ? null : _uploadAvatar,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Display Name
            Text(
              _displayName ?? 'No Name',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 8),

            // Email
            Text(
              _email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),

            const SizedBox(height: 16),

            // Status
            if (_status != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _status!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Profile Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildProfileOption(
                    icon: Icons.edit,
                    title: 'Edit Display Name',
                    subtitle: _displayName ?? 'Set your name',
                    onTap: _editDisplayName,
                  ),
                  _buildProfileOption(
                    icon: Icons.mood,
                    title: 'Change Status',
                    subtitle: _status ?? 'Set your status',
                    onTap: _changeStatus,
                  ),
                  _buildProfileOption(
                    icon: Icons.photo_camera,
                    title: 'Change Avatar',
                    subtitle: 'Upload a profile picture',
                    onTap: _uploadAvatar,
                  ),
                  const Divider(height: 32),
                  _buildProfileOption(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Log out of your account',
                    onTap: _signOut,
                    iconColor: Colors.red,
                    textColor: Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (iconColor ?? Colors.purple).withOpacity(0.1),
        child: Icon(icon, color: iconColor ?? Colors.purple),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
