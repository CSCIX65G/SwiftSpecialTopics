/Library/Developer/Toolchains/armhf-5.1.1-RELEASE_armv6.xctoolchain/usr/bin/swift build --destination /Library/Developer/Destinations/armhf-5.1.1-RELEASE_armv6.json
docker build -f Dockerfile-armv6 --tag computecycles/displayserver:armv6-test .

