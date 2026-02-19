import Foundation

final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private let fileDescriptor: Int32
    private let callback: () -> Void

    init?(path: String, callback: @escaping () -> Void) {
        self.callback = callback
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return nil }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            self?.callback()
        }

        source.setCancelHandler { [fd = fileDescriptor] in
            close(fd)
        }

        self.source = source
        source.resume()
    }

    deinit {
        source?.cancel()
    }
}
