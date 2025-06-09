#!/bin/zsh

# Script to help create the required Firestore index manually

echo "===== SimpleChat Firestore Index Creation Helper ====="
echo ""
echo "This script will help you create the required index for the SimpleChat app."
echo "Follow the steps below:"
echo ""
echo "1. Make sure you're logged in to Firebase CLI:"
echo "   Run: firebase login"
echo ""
echo "2. To create the required index directly via the Firebase Console, open:"
echo "   https://console.firebase.google.com/project/simplechat-c5dc1/firestore/indexes"
echo ""
echo "3. Click 'Create index' and enter the following information:"
echo "   - Collection Group: chatRooms"
echo "   - Fields: "
echo "     * Field path: participants, Index type: Array contains"
echo "     * Field path: lastTimestamp, Order: Descending"
echo "   - Query scope: Collection"
echo ""
echo "4. Click 'Create' and wait for the index to be created."
echo ""
echo "Alternatively, you can deploy the index configuration automatically:"
echo "   Run: ./deploy_rules.sh"
echo ""
echo "Note: After the index is created, it may take a few minutes for it to become active."
echo ""

# Check if they want to open the console URL now
read "response?Would you like to open the Firebase Console now? (y/n): "
if [[ "$response" == "y" || "$response" == "Y" ]]; then
  if command -v xdg-open &> /dev/null; then
    xdg-open "https://console.firebase.google.com/project/simplechat-c5dc1/firestore/indexes"
  elif command -v open &> /dev/null; then
    open "https://console.firebase.google.com/project/simplechat-c5dc1/firestore/indexes"
  else
    echo "Please open this URL manually in your browser:"
    echo "https://console.firebase.google.com/project/simplechat-c5dc1/firestore/indexes"
  fi
fi

echo ""
echo "===== End of Index Creation Helper ====="
