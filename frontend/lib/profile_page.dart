import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.api});

  final ApiService api;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final form = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final imagePicker = ImagePicker();

  Json? profile;

  bool loading = true;
  bool editing = false;
  bool saving = false;

  String? error;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void fillFields() {
    nameController.text = profile?['name'] ?? '';
    phoneController.text = profile?['phone'] ?? '';
    emailController.text = profile?['email'] ?? '';
  }

  Future<void> loadProfile() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await widget.api.request('GET', '/users/profile');

      if (!mounted) return;

      setState(() {
        profile = Map<String, dynamic>.from(result as Map);

        fillFields();
      });
    } catch (e) {
      if (mounted) {
        setState(() => error = errorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> changePhoto() async {
    if (saving || loading || profile == null) return;

    setState(() {
      saving = true;
      error = null;
    });

    try {
      final file = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      // ผู้ใช้ปิดหน้าต่างเลือกรูป
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('The image must be smaller than 5 MB.');
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Change profile photo?'),
          content: SizedBox(
            width: 220,
            height: 220,
            child: ClipOval(child: Image.memory(bytes, fit: BoxFit.cover)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      final updated = await widget.api.uploadAvatar(bytes);

      if (!mounted) return;

      setState(() {
        // เปลี่ยนเฉพาะรูป เพื่อไม่ทับข้อความที่กำลังแก้ไข
        profile!['avatarUrl'] = updated['avatarUrl'];
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } catch (e) {
      if (mounted) {
        setState(() => error = errorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void cancelEditing() {
    setState(() {
      fillFields();
      editing = false;
      error = null;
      form.currentState?.reset();
    });
  }

  Future<void> saveProfile() async {
    if (!form.currentState!.validate()) return;

    setState(() {
      saving = true;
      error = null;
    });

    try {
      final result = await widget.api.request(
        'PATCH',
        '/users/profile',
        body: {
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
        },
      );

      if (!mounted) return;

      setState(() {
        profile = Map<String, dynamic>.from(result as Map);

        fillFields();
        editing = false;
      });

      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('saved')));
    } catch (e) {
      if (mounted) {
        setState(() => error = errorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget avatarWidget() {
    final colors = Theme.of(context).colorScheme;

    final avatarPath = profile?['avatarUrl'] as String?;

    final avatarUrl = avatarPath == null
        ? null
        : Uri.parse('${ApiService.baseUrl}/').resolve(avatarPath).toString();

    final fallback = Icon(Icons.person, size: 48, color: colors.onSurface);

    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Change profile photo',
          child: InkWell(
            onTap: saving ? null : changePhoto,
            customBorder: const CircleBorder(),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                  ),
                  child: ClipOval(
                    child: avatarUrl == null
                        ? Center(child: fallback)
                        : Image.network(
                            avatarUrl,
                            key: ValueKey(avatarUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) {
                              return Center(child: fallback);
                            },
                          ),
                  ),
                ),
                CircleAvatar(
                  radius: 17,
                  backgroundColor: colors.primary,
                  child: Icon(
                    Icons.photo_library_outlined,
                    size: 18,
                    color: colors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: saving ? null : changePhoto,
          child: Text(saving ? 'Please wait...' : 'Change photo'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error ?? 'unable to load profile',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: loadProfile,
                child: const Text('please try again'),
              ),
            ],
          ),
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Center(child: avatarWidget()),
              const SizedBox(height: 20),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Name'),
                const SizedBox(height: 8),

                TextFormField(
                  controller: nameController,
                  readOnly: !editing || saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'your name'),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'please fill your name';
                    }

                    if (text.length > 100) {
                      return 'name cannot be longer than 100 letters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),
                const Text('Phone'),
                const SizedBox(height: 8),

                TextFormField(
                  controller: phoneController,
                  readOnly: !editing || saving,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'phone number'),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    if (text.length > 30) {
                      return 'phone number cannot be longer than 30 letters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),
                const Text('Email'),
                const SizedBox(height: 8),

                TextFormField(
                  controller: emailController,
                  readOnly: !editing || saving,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(hintText: 'Email'),
                  validator: (value) {
                    final text = value?.trim() ?? '';

                    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch(text);

                    return valid ? null : 'invalid email';
                  },
                ),

                if (editing)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'If you change your email'
                      'please use new email next time you login',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),

                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(error!, style: TextStyle(color: colors.error)),
                  ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (editing) ...[
                      TextButton(
                        onPressed: saving ? null : cancelEditing,
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                    ],

                    FilledButton(
                      onPressed: saving
                          ? null
                          : editing
                          ? saveProfile
                          : () {
                              setState(() {
                                editing = true;
                                error = null;
                              });
                            },
                      child: Text(
                        saving
                            ? 'Saving...'
                            : editing
                            ? 'Save'
                            : 'Edit',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
