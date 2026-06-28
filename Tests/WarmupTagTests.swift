import Testing
@testable import IDKPlay

struct WarmupTagTests {

    @Test("Detects the canonical warmup tag")
    func detectsCanonical() {
        #expect(WarmupTag.detect(in: ["rock", "warmup", "jazz"]) == "warmup")
    }

    @Test("Detects hyphenated and spaced spellings")
    func detectsVariants() {
        #expect(WarmupTag.detect(in: ["warm-up"]) == "warm-up")
        #expect(WarmupTag.detect(in: ["warm up"]) == "warm up")
    }

    @Test("Returns nil when no warmup tag is present")
    func noneWhenAbsent() {
        #expect(WarmupTag.detect(in: ["rock", "jazz"]) == nil)
        #expect(WarmupTag.detect(in: []) == nil)
    }
}
