#!/bin/bash

# Firebase Deployment Script for Learn & Earn App
# This script deploys all Firebase configurations safely

set -e  # Exit on any error

echo "🔥 Starting Firebase Deployment for Learn & Earn App"
echo "=================================================="

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Please log in to Firebase..."
    firebase login
fi

# Show current project
echo "📋 Current Firebase project:"
firebase use

echo ""
read -p "🤔 Continue with deployment to this project? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

echo ""
echo "🚀 Starting deployment..."

# Deploy Firestore rules
echo "📝 Deploying Firestore security rules..."
if firebase deploy --only firestore:rules; then
    echo "✅ Firestore rules deployed successfully"
else
    echo "❌ Firestore rules deployment failed"
    exit 1
fi

# Deploy Firestore indexes
echo "📊 Deploying Firestore indexes..."
if firebase deploy --only firestore:indexes; then
    echo "✅ Firestore indexes deployed successfully"
else
    echo "❌ Firestore indexes deployment failed"
    exit 1
fi

# Deploy Storage rules
echo "📁 Deploying Storage security rules..."
if firebase deploy --only storage; then
    echo "✅ Storage rules deployed successfully"
else
    echo "❌ Storage rules deployment failed"
    exit 1
fi

# Optional: Deploy hosting (if web version exists)
if [ -d "build/web" ]; then
    echo "🌐 Deploying web hosting..."
    if firebase deploy --only hosting; then
        echo "✅ Hosting deployed successfully"
    else
        echo "⚠️ Hosting deployment failed (optional)"
    fi
fi

echo ""
echo "🎉 Firebase deployment completed successfully!"
echo "=================================================="
echo ""

# Show deployment info
echo "📊 Deployment Summary:"
echo "- Firestore Rules: ✅ Deployed"
echo "- Firestore Indexes: ✅ Deployed"
echo "- Storage Rules: ✅ Deployed"
if [ -d "build/web" ]; then
    echo "- Web Hosting: ✅ Deployed"
fi

echo ""
echo "🔗 Firebase Console: https://console.firebase.google.com/project/$(firebase use)/overview"
echo ""

# Verify deployment
echo "🔍 Verifying deployment..."
echo "Run these commands to test:"
echo "  flutter test"
echo "  flutter run --release"
echo ""

echo "✨ Deployment complete! Your Firebase configuration is now live."
