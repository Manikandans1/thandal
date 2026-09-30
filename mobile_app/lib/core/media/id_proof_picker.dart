import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';

/// A photo/scan of an ID document chosen by the user.
class PickedProof {
  final String path;
  final String filename;
  final String contentType;
  const PickedProof({required this.path, required this.filename, required this.contentType});

  UploadFile toUpload(String field) =>
      UploadFile(field: field, path: path, filename: filename, contentType: contentType);
}

/// Asks "Take photo / Choose from gallery", then returns the picked image (or null if cancelled).
/// Images are scaled down so the upload stays well under the server's 8 MB limit.
Future<PickedProof?> pickIdProofPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  try {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );
    if (file == null) return null;
    final lower = file.path.toLowerCase();
    final isPng = lower.endsWith('.png');
    final name = file.path.split('/').last.split('\\').last;
    return PickedProof(
      path: file.path,
      filename: name.isEmpty ? (isPng ? 'id-proof.png' : 'id-proof.jpg') : name,
      contentType: isPng ? 'image/png' : 'image/jpeg',
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery. Check app permissions.')),
      );
    }
    return null;
  }
}

/// The server's document type keys, keyed by the label shown in the apps.
const Map<String, String> kDocTypeKeys = {
  'Aadhaar': 'aadhaar_card',
  'Aadhaar card': 'aadhaar_card',
  'PAN': 'pan_card',
  'PAN card': 'pan_card',
  'Voter ID': 'voter_id',
  'Driving Licence': 'driving_licence',
  'Driving licence': 'driving_licence',
  'Passport': 'passport',
  'Ration card': 'ration_card',
};

String docTypeKey(String label) => kDocTypeKeys[label] ?? 'aadhaar_card';
