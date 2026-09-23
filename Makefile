# Sip & Stretch — common tasks. Run `make help` for the list.

APP      := build/SipStretch.app
VERSION  := $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Support/Info.plist)
# The Command Line Tools ship swift-testing's macro plugin but don't put it on the search path.
# (Under Xcode this directory doesn't exist and the flag is skipped.)
TESTING_PLUGINS := $(wildcard $(shell xcode-select -p)/usr/lib/swift/host/plugins/testing)
TEST_FLAGS := $(if $(TESTING_PLUGINS),-Xswiftc -plugin-path -Xswiftc $(TESTING_PLUGINS))

.PHONY: help build test app run install zip release icon snapshots clean

help: ## Show this help
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  make %-10s %s\n", $$1, $$2}'

build: ## Debug build of the package
	swift build

test: ## Run the unit tests
	swift test $(TEST_FLAGS)

app: ## Build build/SipStretch.app (release, ad-hoc signed)
	scripts/bundle.sh build

run: app ## Build the app and launch it (restarting any running copy)
	-@pkill -x SipStretch 2>/dev/null; sleep 0.5
	open $(APP)

install: app ## Copy the app to /Applications and launch it
	-@pkill -x SipStretch 2>/dev/null; sleep 0.5
	rm -rf /Applications/SipStretch.app
	cp -R $(APP) /Applications/
	open /Applications/SipStretch.app

zip: ## Universal release zip in dist/
	UNIVERSAL=1 scripts/bundle.sh build
	mkdir -p dist
	rm -f dist/SipStretch-$(VERSION).zip
	ditto -c -k --keepParent $(APP) dist/SipStretch-$(VERSION).zip
	@echo "✓ dist/SipStretch-$(VERSION).zip"

release: ## Universal, Developer ID-signed, notarized zip (needs SIGN_IDENTITY + NOTARY_PROFILE; see docs/RELEASING.md)
	@test -n "$(SIGN_IDENTITY)" || { echo "✗ Set SIGN_IDENTITY=\"Developer ID Application: Name (TEAMID)\""; exit 1; }
	UNIVERSAL=1 SIGN_IDENTITY="$(SIGN_IDENTITY)" scripts/bundle.sh build
	scripts/notarize.sh

icon: ## Regenerate Support/AppIcon.icns and docs/icon.png
	swift scripts/make-icon.swift Support
	mv Support/AppIcon-1024.png docs/icon.png

snapshots: build ## Regenerate the README screenshots in docs/screenshots
	.build/debug/SipStretch --snapshots docs/screenshots

clean: ## Remove build products
	rm -rf .build build dist
