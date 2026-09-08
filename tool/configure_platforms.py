from pathlib import Path
import json
import re
import sys

root = Path(sys.argv[1]).resolve()
assert root.name == 'flutter_ecommerce_app'
android = root / 'android/app/src/main/AndroidManifest.xml'
text = android.read_text()
text = text.replace('android:label="flutter_ecommerce_app"', 'android:label="MagisStore"')
if 'android.permission.CAMERA' not in text:
    text = text.replace('    <application', '    <uses-permission android:name="android.permission.CAMERA" />\n    <uses-feature android:name="android.hardware.camera" android:required="false" />\n    <application')
android.write_text(text)
ios = root / 'ios/Runner/Info.plist'
text = ios.read_text().replace('<string>Flutter Ecommerce App</string>', '<string>MagisStore</string>')
if 'NSCameraUsageDescription' not in text:
    text = text.replace('<dict>', '<dict>\n\t<key>NSCameraUsageDescription</key>\n\t<string>Scan MagisStore demo claim tickets at the staff pickup desk.</string>', 1)
ios.write_text(text)
web = root / 'web/index.html'
text = web.read_text().replace('A new Flutter project.', 'Your campus essentials. Shop MagisStore and collect at the bookstore express lane.').replace('flutter_ecommerce_app', 'MagisStore')
web.write_text(text)
manifest = root / 'web/manifest.json'
data = json.loads(manifest.read_text())
data.update(name='MagisStore', short_name='MagisStore', background_color='#003366', theme_color='#003366', description='Campus essentials and express pickup demo')
manifest.write_text(json.dumps(data, indent=2))
viewer = root / 'lib/product_viewer.dart'
text = viewer.read_text()
text = re.sub(r'\brotate\(', '_rotate(', text).replace('.map(rotate)', '.map(_rotate)')
text = re.sub(r'\bextrude\(', '_extrude(', text)
viewer.write_text(text)
print('Configured app identity, camera permissions, and private renderer helpers.')
