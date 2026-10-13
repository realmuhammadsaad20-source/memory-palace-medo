import os

path = 'android/app/src/main/AndroidManifest.xml'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    perms = """
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.CAMERA" />
"""
    if 'android.permission.CAMERA' not in content:
        content = content.replace('<application', perms + '    <application')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print('Permissions injected successfully')
    else:
        print('Permissions already present')
else:
    print('AndroidManifest.xml not found at', path)
