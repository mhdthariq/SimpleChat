#!/bin/zsh
# Script to deploy Firestore rules and indexes

echo "Preparing to deploy Firestore security rules and indexes..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLI not found. Installing Firebase CLI..."
    npm install -g firebase-tools
fi

# Check if user is logged in
LOGGED_IN=$(firebase projects:list 2>&1 | grep -v "Error: Failed to list Firebase projects")
if [[ -z "$LOGGED_IN" ]]; then
    echo "You need to log in first"
    firebase login
fi

# Get the current directory
CURRENT_DIR=$(pwd)
RULES_FILE="$CURRENT_DIR/firestore.rules"
INDEXES_FILE="$CURRENT_DIR/firestore.indexes.json"
CONFIG_FILE="$CURRENT_DIR/firebase.json"

# Check if the rules file exists
if [[ ! -f "$RULES_FILE" ]]; then
    echo "Error: firestore.rules file not found at $RULES_FILE"
    exit 1
fi

# Check if firebase.json exists and is properly configured
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: firebase.json file not found at $CONFIG_FILE"
    exit 1
fi

# Check if the config file contains the firestore section
if ! grep -q '"firestore"' "$CONFIG_FILE"; then
    echo "Error: firebase.json does not contain firestore configuration"
    exit 1
fi

echo "Deploying Firestore security rules from $RULES_FILE..."

# For debugging, print the rules file content
echo "Rules file content:"
cat "$RULES_FILE"
echo ""

# Deploy the rules with --debug flag for more information
firebase deploy --only firestore:rules --debug

echo ""
echo "==================================================="
echo "Deployment completed!"
echo ""
echo "If you're still missing an index, you can create it manually:"
echo "1. Go to Firebase Console > Firestore Database > Indexes"
echo "2. Click 'Create Index' and add:"
echo "   - Collection: chatRooms"
echo "   - Fields:"
echo "     * participants (Array contains)"
echo "     * lastTimestamp (Descending)"
echo "==================================================="
