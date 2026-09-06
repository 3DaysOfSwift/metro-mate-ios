import Testing
@testable import Metronome

struct NoteValueTests {
    @Test func noteValuesDescribeTheirExistingRhythm() {
        #expect(NoteValue.quarter.multiplier == 1)
        #expect(NoteValue.quarter.beatsPerMeasure == 4)
        #expect(NoteValue.quarter.displayName == "♩")

        #expect(NoteValue.eighth.multiplier == 2)
        #expect(NoteValue.eighth.beatsPerMeasure == 8)
        #expect(NoteValue.eighth.displayName == "♪")

        #expect(NoteValue.sixteenth.multiplier == 4)
        #expect(NoteValue.sixteenth.beatsPerMeasure == 16)
        #expect(NoteValue.sixteenth.displayName == "♬")

        #expect(NoteValue.quarterTriplet.multiplier == 1.5)
        #expect(NoteValue.quarterTriplet.beatsPerMeasure == 3)
        #expect(NoteValue.quarterTriplet.displayName == "♩₃")

        #expect(NoteValue.eighthTriplet.multiplier == 3)
        #expect(NoteValue.eighthTriplet.beatsPerMeasure == 6)
        #expect(NoteValue.eighthTriplet.displayName == "♪₃")

        #expect(NoteValue.sixteenthTriplet.multiplier == 6)
        #expect(NoteValue.sixteenthTriplet.beatsPerMeasure == 12)
        #expect(NoteValue.sixteenthTriplet.displayName == "♬₃")
    }

    @Test func onlyTripletValuesIdentifyAsTriplets() {
        #expect(NoteValue.quarter.isTriplet == false)
        #expect(NoteValue.eighth.isTriplet == false)
        #expect(NoteValue.sixteenth.isTriplet == false)
        #expect(NoteValue.quarterTriplet.isTriplet)
        #expect(NoteValue.eighthTriplet.isTriplet)
        #expect(NoteValue.sixteenthTriplet.isTriplet)
    }

    @Test func andCountingUsesTheExistingEighthNoteLanguage() {
        let labels = (0..<8).map {
            GridDisplayMode.andCounting.getLabel(for: $0, noteValue: .eighth)
        }

        #expect(labels == ["1", "&", "2", "&", "3", "&", "4", "&"])
    }

    @Test func subdivisionCountingUsesTheExistingSixteenthNoteLanguage() {
        let labels = (0..<8).map {
            GridDisplayMode.subdivisionCounting.getLabel(for: $0, noteValue: .sixteenth)
        }

        #expect(labels == ["1", "e", "&", "a", "2", "e", "&", "a"])
    }

    @Test func subdivisionCountingUsesTripLetLanguageForTriplets() {
        let labels = (0..<6).map {
            GridDisplayMode.subdivisionCounting.getLabel(for: $0, noteValue: .eighthTriplet)
        }

        #expect(labels == ["1", "trip", "let", "2", "trip", "let"])
    }
}
