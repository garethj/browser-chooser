.PHONY: build bundle install clean run test list-browsers

build:
	swift build -c release

bundle: build
	bash Scripts/build.sh

install: bundle
	bash Scripts/install.sh

clean:
	swift package clean
	rm -rf .build/BrowserChooser.app

run: bundle
	.build/BrowserChooser.app/Contents/MacOS/BrowserChooser

test:
	swift test

list-browsers: bundle
	.build/BrowserChooser.app/Contents/MacOS/BrowserChooser --list-browsers
