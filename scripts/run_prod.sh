#!/bin/bash

# Run the app in production mode
echo "🚀 Starting app in PRODUCTION mode..."
flutter run --dart-define=ENVIRONMENT=production --dart-define=ENABLE_LOGGING=false

