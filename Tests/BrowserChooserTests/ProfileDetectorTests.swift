import Testing
@testable import BrowserChooser

@Suite("ProfileDetector")
struct ProfileDetectorTests {
    @Test("Parses profiles.ini into folder name -> display name")
    func parsesProfilesIni() {
        let ini = """
        [Profile1]
        Name=default
        IsRelative=1
        Path=Profiles/gt336weu.default
        Default=1

        [Profile0]
        Name=default-release
        IsRelative=1
        Path=Profiles/6eov930b.default-release
        StoreID=e7e11840

        [General]
        StartWithLastProfile=1
        Version=2
        """

        let names = ProfileDetector.parseProfilesIni(ini)

        #expect(names["gt336weu.default"] == "default")
        #expect(names["6eov930b.default-release"] == "default-release")
        #expect(names.count == 2)
    }

    @Test("Recognized Firefox bundle IDs resolve to a Profiles directory")
    func geckoProfilesDirectoryForKnownBundleID() {
        let dir = ProfileDetector.geckoProfilesDirectory(forBundleID: "org.mozilla.firefox")

        #expect(dir?.lastPathComponent == "Profiles")
        #expect(dir?.deletingLastPathComponent().lastPathComponent == "Firefox")
    }

    @Test("Unknown bundle IDs (including Chromium ones) return nil")
    func geckoProfilesDirectoryForUnknownBundleID() {
        #expect(ProfileDetector.geckoProfilesDirectory(forBundleID: "com.google.Chrome") == nil)
        #expect(ProfileDetector.geckoProfilesDirectory(forBundleID: "com.apple.Safari") == nil)
    }
}
