#!/bin/bash

# Build production APK
echo "🏗️  Building PRODUCTION APK..."
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=ENABLE_LOGGING=false

echo "✅ Build complete! APK location:"
echo "   build/app/outputs/flutter-apk/app-release.apk"

