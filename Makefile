.PHONY: build bundle install clean run test list-browsers icon

# Build output lives outside the project: this folder syncs via Google Drive, which
# mangles SwiftPM's .build directory (e.g. replacing .dSYM bundles with empty files).
BUILD_PATH ?= $(HOME)/Library/Caches/browser-chooser/build
export BUILD_PATH
APP := $(BUILD_PATH)/BrowserChooser.app

build:
	swift build -c release --scratch-path "$(BUILD_PATH)"

bundle: build
	bash Scripts/build.sh

install: bundle
	bash Scripts/install.sh

clean:
	swift package clean --scratch-path "$(BUILD_PATH)"
	rm -rf "$(APP)"

run: bundle
	"$(APP)/Contents/MacOS/BrowserChooser"

test:
	swift test --scratch-path "$(BUILD_PATH)"

list-browsers: bundle
	"$(APP)/Contents/MacOS/BrowserChooser" --list-browsers

icon:
	swift Scripts/make-icon.swift
