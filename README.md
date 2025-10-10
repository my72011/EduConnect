EduConnect Full Working Package (Flutter + Node.js)

Contents:
- flutter_app/       => Flutter project with all pages (lib/main.dart, pubspec.yaml, assets/logo.png)
- server.js          => Node.js server for Zoom integration & groups
- package.json       => Node server dependencies
- .env.example       => copy to .env and fill Zoom credentials

How to run (overview):

1) Node.js server (optional but required for Zoom integration and real group notifications):
   - copy .env.example -> .env and fill Zoom credentials (ZOOM_ACCOUNT_ID, ZOOM_CLIENT_ID, ZOOM_CLIENT_SECRET)
   - npm install
   - node server.js
   - server runs on http://localhost:3000

2) Flutter app:
   - Open flutter_app folder
   - flutter pub get
   - Replace assets/logo.png with your real PNG logo.
   - Run on device/emulator:
       flutter run
   - Or build release APK:
       flutter build apk --release

Notes:
- image_picker needs camera/gallery permissions in AndroidManifest and Info.plist.
- For testing Zoom creation, ensure the host_email you pass exists in your Zoom account.
- This package is a local demo: data is stored in memory and NotificationsStore. For production use a database.
