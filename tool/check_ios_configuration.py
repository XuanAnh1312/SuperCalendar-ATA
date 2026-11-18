"""Validate iOS bundle/Firebase/permission configuration without macOS."""
import json
import plistlib
from pathlib import Path
import re

root = Path(__file__).resolve().parent.parent
info = plistlib.loads((root / 'ios/Runner/Info.plist').read_bytes())
firebase = plistlib.loads((root / 'ios/Runner/GoogleService-Info.plist').read_bytes())
project = (root / 'ios/Runner.xcodeproj/project.pbxproj').read_text()
options = (root / 'lib/firebase_options.dart').read_text()
workflow = (root / '.github/workflows/dart.yml').read_text()
assert info['CFBundleDisplayName'] == 'SuperCalendar'
for key in ('NSPhotoLibraryUsageDescription', 'NSPhotoLibraryAddUsageDescription',
            'NSCalendarsUsageDescription', 'NSCalendarsFullAccessUsageDescription'):
    assert info.get(key), f'Missing permission explanation: {key}'
assert info['GIDClientID'] == firebase['CLIENT_ID']
schemes = [s for item in info['CFBundleURLTypes'] for s in item['CFBundleURLSchemes']]
assert firebase['REVERSED_CLIENT_ID'] in schemes
bundle_ids = re.findall(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);', project)
assert bundle_ids and all(b == firebase['BUNDLE_ID'] or b == firebase['BUNDLE_ID'] + '.RunnerTests' for b in bundle_ids), bundle_ids
assert project.count('GoogleService-Info.plist in Resources */,') == 1
ios_options = options.split('static const FirebaseOptions ios =', 1)[1]
for key in ('GOOGLE_APP_ID', 'PROJECT_ID', 'BUNDLE_ID', 'CLIENT_ID'):
    assert firebase[key] in ios_options, f'Firebase mismatch: {key}'
metadata = json.loads((root / 'firebase.json').read_text())
assert metadata['flutter']['platforms']['ios']['default']['appId'] == firebase['GOOGLE_APP_ID']
assert "platform :ios, '15.0'" in (root / 'ios/Podfile').read_text()
assert '--no-codesign' in workflow
print('iOS configuration checks passed: bundle, permissions, Firebase, Google callback, resources, Podfile and unsigned workflow.')
