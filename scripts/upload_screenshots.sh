#!/bin/bash
set -e
echo "Uploading KR..."
asc screenshots upload --version-localization "93643a42-f682-4c10-87d7-e85f8bb0d508" --path "./assets/appstore/KR" --device-type "APP_IPHONE_65"
echo "Uploading JP..."
asc screenshots upload --version-localization "c39480e3-1376-4a52-a226-2b864cfdf8bc" --path "./assets/appstore/JP" --device-type "APP_IPHONE_65"
echo "Uploading ENG..."
asc screenshots upload --version-localization "261a2394-b8a3-4035-8abb-f0f835e21c6d" --path "./assets/appstore/ENG" --device-type "APP_IPHONE_65"
echo "Uploading CN..."
asc screenshots upload --version-localization "df0e27b5-092d-42fd-90e9-e502ce4345f7" --path "./assets/appstore/CN" --device-type "APP_IPHONE_65"
echo "Done."
