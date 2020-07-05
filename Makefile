# Variables


# targets

archive: clean
	xcodebuild archive -scheme SwiftRulesEngine -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild archive -scheme SwiftRulesEngine -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild -create-xcframework -framework ./build/ios_simulator.xcarchive/Products/Library/Frameworks/SwiftRulesEngine.framework -framework ./build/ios.xcarchive/Products/Library/Frameworks/SwiftRulesEngine.framework -output ./build/SwiftRulesEngine.xcframework

clean:
	rm -rf ./build

