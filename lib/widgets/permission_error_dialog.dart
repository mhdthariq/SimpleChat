// File: lib/widgets/permission_error_dialog.dart
import 'package:flutter/material.dart';
import '../utils/permission_checker.dart';

class PermissionErrorDialog extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const PermissionErrorDialog({
    Key? key,
    required this.errorMessage,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Permission Error'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You do not have permission to access this data.'),
          const SizedBox(height: 8),
          Text(
            'This could be due to:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('1. Firestore security rules not deployed properly'),
          Text('2. You are not authenticated'),
          Text('3. You do not have access to this specific data'),
          const SizedBox(height: 8),
          Text(
            'Error details:',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
          Text(
            errorMessage,
            style: TextStyle(fontSize: 11, color: Colors.red[700]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            // Run permission checker to diagnose and fix issues
            await PermissionChecker.checkPermissions(context);
          },
          child: const Text('CHECK PERMISSIONS'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onRetry();
          },
          child: const Text('RETRY'),
        ),
      ],
    );
  }
}
