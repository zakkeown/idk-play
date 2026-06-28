import Foundation

extension Int {
    /// Seconds as a clock string: "4:05" or "1:02:30".
    var asDurationString: String {
        let h = self / 3600
        let m = (self % 3600) / 60
        let s = self % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}

extension Collection where Element == Song {
    /// Distinct tags across the collection, sorted for stable display.
    var distinctTags: [String] {
        Set(flatMap { $0.tags }).sorted()
    }
}
