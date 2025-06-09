#!/bin/zsh
# Script to check and report application status

echo "===== SimpleChat App Status Check ====="
echo ""

# Check Flutter version
echo "Flutter SDK Version:"
flutter --version | head -1
echo ""

# Check Firebase configuration
echo "Firebase Configuration:"
if [[ -f "lib/firebase_options.dart" ]]; then
    echo "✅ Firebase configuration file found at lib/firebase_options.dart"
else
    echo "❌ Firebase configuration file missing. Run 'flutterfire configure' to set up Firebase."
fi
echo ""

# Check Firestore rules
echo "Firestore Security Rules:"
if [[ -f "firestore.rules" ]]; then
    echo "✅ Firestore security rules found"
    RULES_VERSION=$(grep "rules_version" firestore.rules | head -1)
    echo "   $RULES_VERSION"
    
    # Check for user rules
    if grep -q "match /users/{userId}" firestore.rules; then
        echo "   ✅ Users collection rules defined"
    else
        echo "   ❌ Users collection rules missing"
    fi
    
    # Check for chat rooms rules
    if grep -q "match /chatRooms/{roomId}" firestore.rules; then
        echo "   ✅ Chat rooms collection rules defined"
    else
        echo "   ❌ Chat rooms collection rules missing"
    fi
else
    echo "❌ Firestore security rules file missing"
fi
echo ""

# Check pub dependencies
echo "Package Dependencies:"
flutter pub outdated | grep "Dependencies|direct"
echo ""

echo "===== End of Status Check ====="
echo ""
echo "Instructions to fix common issues:"
echo "1. If users don't appear, check the Firestore 'users' collection in Firebase Console"
echo "2. For the missing index error, run the app and use the 'Create Index' button in the dialog"
echo "3. To deploy Firestore rules: ./deploy_rules.sh"
echo ""
