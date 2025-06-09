#!/bin/zsh
# Test script for SimpleChat permissions

echo "===== SimpleChat Permission Test ====="
echo ""
echo "This script will test the Firestore security rules by simulating different access patterns"
echo "to verify that our fixes have resolved the permission issues."
echo ""

# Use the Firebase Local Emulator Suite for testing
# https://firebase.google.com/docs/emulator-suite

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLI not found. Installing Firebase CLI..."
    npm install -g firebase-tools
fi

# Check if rules test file exists, create it if not
RULES_TEST_FILE="test_rules.spec.js"
if [[ ! -f "$RULES_TEST_FILE" ]]; then
    echo "Creating rules test file..."
    cat > "$RULES_TEST_FILE" << 'EOF'
// Rules test file for SimpleChat
const assert = require('assert');
const firebase = require('@firebase/rules-unit-testing');

const PROJECT_ID = "simplechat-test";

function getFirestore(auth) {
  return firebase.initializeTestApp({ 
    projectId: PROJECT_ID, 
    auth 
  }).firestore();
}

function getAdminFirestore() {
  return firebase.initializeAdminApp({ projectId: PROJECT_ID }).firestore();
}

beforeEach(async () => {
  await firebase.clearFirestoreData({ projectId: PROJECT_ID });
});

describe('SimpleChat Firestore Rules', () => {
  // User document tests
  it('allows users to read their own user document', async () => {
    const db = getFirestore({ uid: 'user1' });
    const adminDb = getAdminFirestore();
    
    // Create test data
    await adminDb.collection('users').doc('user1').set({
      uid: 'user1',
      displayName: 'Test User 1',
      email: 'user1@example.com',
      lastSeen: firebase.firestore.FieldValue.serverTimestamp()
    });
    
    // Verify read works
    const userDoc = await db.collection('users').doc('user1').get();
    assert.equal(userDoc.exists, true);
  });
  
  // Chat rooms tests
  it('allows users to read chat rooms where they are a participant', async () => {
    const db = getFirestore({ uid: 'user1' });
    const adminDb = getAdminFirestore();
    
    // Create test data
    await adminDb.collection('chatRooms').doc('room1').set({
      participants: ['user1', 'user2'],
      lastMessage: 'Hello',
      lastTimestamp: firebase.firestore.FieldValue.serverTimestamp()
    });
    
    // Verify read works
    const roomDoc = await db.collection('chatRooms').doc('room1').get();
    assert.equal(roomDoc.exists, true);
  });
  
  // Test document ID pattern matching
  it('allows users to read chat rooms with their ID in the document ID', async () => {
    const db = getFirestore({ uid: 'user1' });
    const adminDb = getAdminFirestore();
    
    // Create test data with ID that contains the user ID
    await adminDb.collection('chatRooms').doc('chat_user1_user2').set({
      participants: ['user2'],  // Purposely not including user1 to test pattern matching
      lastMessage: 'Hello',
      lastTimestamp: firebase.firestore.FieldValue.serverTimestamp()
    });
    
    // Verify read works because of ID pattern even though user not in participants
    const roomDoc = await db.collection('chatRooms').doc('chat_user1_user2').get();
    assert.equal(roomDoc.exists, true);
  });
  
  // Test messages subcollection
  it('allows users to read and write messages in a chat room they participate in', async () => {
    const db = getFirestore({ uid: 'user1' });
    const adminDb = getAdminFirestore();
    
    // Create test data
    await adminDb.collection('chatRooms').doc('room1').set({
      participants: ['user1', 'user2'],
      lastMessage: 'Hello',
      lastTimestamp: firebase.firestore.FieldValue.serverTimestamp()
    });
    
    // Add a message to the subcollection
    await adminDb.collection('chatRooms').doc('room1').collection('messages').doc('msg1').set({
      senderId: 'user2',
      text: 'Hello user1',
      timestamp: firebase.firestore.FieldValue.serverTimestamp()
    });
    
    // Verify read works
    const msgQuery = await db.collection('chatRooms').doc('room1').collection('messages').get();
    assert.equal(msgQuery.empty, false);
    
    // Verify write works
    await db.collection('chatRooms').doc('room1').collection('messages').add({
      senderId: 'user1',
      text: 'Hello back!',
      timestamp: firebase.firestore.FieldValue.serverTimestamp()
    });
    
    // This should have worked without throwing a permission error
  });
});

after(async () => {
  await firebase.clearFirestoreData({ projectId: PROJECT_ID });
});
EOF
fi

# Install necessary dependencies for testing
echo "Installing test dependencies..."
npm install --no-save firebase @firebase/rules-unit-testing mocha

# Run the tests
echo ""
echo "Running permission tests..."
npx mocha "$RULES_TEST_FILE"

echo ""
echo "===== End of Permission Test ====="
