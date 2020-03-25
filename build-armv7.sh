/Library/Developer/Toolchains/armhf-5.1.1-raspbian-RELEASE.xctoolchain/usr/bin/swift build --destination /Library/Developer/Destinations/armhf-5.1.1-raspbian-RELEASE.json
docker build -f Dockerfile-armv7 --tag computecycles/displayserver:armv7-latest .

