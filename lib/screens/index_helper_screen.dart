import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class IndexHelper extends StatelessWidget {
  const IndexHelper({super.key});

  // URL for the index creation - copy this from your error message
  static const String indexUrl =
      "https://console.firebase.google.com/v1/r/project/simplechat-c5dc1/firestore/indexes?create_composite=ClJwcm9qZWN0cy9zaW1wbGVjaGF0LWM1ZGMxL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9jaGF0Um9vbXMvaW5kZXhlcy9fEAEaEAoMcGFydGljaXBhbnRzGAEaEQoNbGFzdFRpbWVzdGFtcBACGgwKCF9fbmFtZV9fEAI";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Required Index')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Missing Firestore Index',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your app requires a Firestore index to load chat rooms properly. The error occurred because this index does not exist yet.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Index Details:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildIndexInfo(),
            const SizedBox(height: 24),
            const Text(
              'To fix this issue, tap the button below to create the required index in your Firebase project:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Create Firestore Index'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: _launchIndexUrl,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Note: After creating the index, it may take a few minutes for it to be ready. Once the index is active, your app will work properly.',
              style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Collection: chatRooms',
            style: TextStyle(fontFamily: 'monospace'),
          ),
          Divider(),
          Text('Fields:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            '• participants (array-contains)',
            style: TextStyle(fontFamily: 'monospace'),
          ),
          Text(
            '• lastTimestamp (descending)',
            style: TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchIndexUrl() async {
    final Uri url = Uri.parse(indexUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
