test:
    xcodebuild \
        -project iBeaconCentralSample.xcodeproj \
        -sdk iphonesimulator \
        -scheme iBeaconCentralSample \
        -configuration Debug \
        -destination 'platform=iOS Simulator,name=iPhone 6,0S=8.1' \
        clean build test