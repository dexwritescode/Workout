ANDROID_HOME ?= $(HOME)/Library/Android/sdk
JAVA_HOME    ?= /Users/dex/Applications/Android Studio.app/Contents/jbr/Contents/Home

IOS_PROJECT := ios/Workout.xcodeproj
IOS_SCHEME  := Workout
IOS_SIM     := iPhone 17 Pro
IOS_BUNDLE  := com.example.Workout

ANDROID_DIR := android
ANDROID_AVD := Pixel_10_Pro
ANDROID_PKG := com.dexwritescode.workout
ANDROID_APK := $(ANDROID_DIR)/app/build/outputs/apk/debug/app-debug.apk

ADB      := $(ANDROID_HOME)/platform-tools/adb
EMULATOR := $(ANDROID_HOME)/emulator/emulator

.DEFAULT_GOAL := help

# ── iOS ───────────────────────────────────────────────────────────────────────

.PHONY: ios-build
ios-build: ## Build iOS app (simulator, no signing)
	xcodebuild \
		-project $(IOS_PROJECT) \
		-scheme $(IOS_SCHEME) \
		-configuration Debug \
		-sdk iphonesimulator \
		CODE_SIGNING_ALLOWED=NO \
		build

.PHONY: ios-test
ios-test: ## Run iOS unit tests on iPhone 17 Pro
	xcodebuild test \
		-project $(IOS_PROJECT) \
		-scheme $(IOS_SCHEME) \
		-destination "platform=iOS Simulator,name=$(IOS_SIM)" \
		CODE_SIGNING_ALLOWED=NO

.PHONY: ios-run
ios-run: ## Build + launch iOS app in simulator
	@SIM_ID=$$(xcrun simctl list devices available | grep "$(IOS_SIM)" | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/') && \
	xcodebuild \
		-project $(IOS_PROJECT) \
		-scheme $(IOS_SCHEME) \
		-configuration Debug \
		-destination "platform=iOS Simulator,id=$$SIM_ID" \
		CODE_SIGNING_ALLOWED=NO \
		build && \
	xcrun simctl boot $$SIM_ID 2>/dev/null || true && \
	open -a Simulator && \
	APP_PATH=$$(find ~/Library/Developer/Xcode/DerivedData -name "$(IOS_SCHEME).app" -path "*iphonesimulator*" 2>/dev/null | head -1) && \
	xcrun simctl install $$SIM_ID "$$APP_PATH" && \
	xcrun simctl launch $$SIM_ID $(IOS_BUNDLE)

# ── Android ───────────────────────────────────────────────────────────────────

.PHONY: android-build
android-build: ## Assemble debug APK
	cd $(ANDROID_DIR) && JAVA_HOME="$(JAVA_HOME)" ANDROID_HOME="$(ANDROID_HOME)" ./gradlew assembleDebug

.PHONY: android-test
android-test: ## Run Android unit tests (JVM)
	cd $(ANDROID_DIR) && JAVA_HOME="$(JAVA_HOME)" ANDROID_HOME="$(ANDROID_HOME)" ./gradlew test

.PHONY: android-run
android-run: ## Build + launch Android app in emulator
	cd $(ANDROID_DIR) && JAVA_HOME="$(JAVA_HOME)" ANDROID_HOME="$(ANDROID_HOME)" ./gradlew assembleDebug
	@$(EMULATOR) -avd $(ANDROID_AVD) -no-snapshot-load &
	@echo "Waiting for emulator..."
	@$(ADB) wait-for-device shell 'while [[ -z $$(getprop sys.boot_completed) ]]; do sleep 2; done'
	@$(ADB) install -r $(ANDROID_APK)
	@$(ADB) shell am start -n $(ANDROID_PKG)/.MainActivity

# ── Help ──────────────────────────────────────────────────────────────────────

.PHONY: help
help: ## Show available targets
	@echo "Usage: make [target]"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  \033[1;32m%-18s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
