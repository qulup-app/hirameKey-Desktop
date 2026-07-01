@testable import Core
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

/// LM ベース修復候補（Phase 2）の絞り込みロジックのテスト。
/// channelCost == 0 は入力を無編集で通過した仮説であり、正しく入力された語に対する
/// 単なる別解釈であって誤字訂正ではないため、Space キー側で先頭に昇格させてはならない。
@Suite struct TypoCorrectionReadingFilterTests {
    /// 正しく入力された語に対して LM が別解釈を返しただけの場合（channelCost == 0）、
    /// 誤字訂正の読みとして採用されないことを確認する。
    @Test func excludesCandidatesReachedWithoutAnyEdit() {
        let candidates = [
            ZenzaiTypoCandidate(correctedInput: "あめ", convertedText: "あめ", score: 0, lmScore: 0, channelCost: 0, prominence: 0),
            ZenzaiTypoCandidate(correctedInput: "あめ", convertedText: "雨", score: 0, lmScore: 0, channelCost: 0, prominence: 0),
        ]
        let readings = SegmentsManager.filterGenuineTypoCorrectionReadings(candidates)
        #expect(readings.isEmpty)
    }

    /// 実際に文字の置換・脱落・転置を経て到達した候補（channelCost > 0）は、
    /// 誤字訂正の読みとして採用されることを確認する。
    @Test func includesCandidatesReachedThroughAnEdit() {
        let candidates = [
            ZenzaiTypoCandidate(correctedInput: "おじゃ", convertedText: "おじゃ", score: 0, lmScore: 0, channelCost: 0, prominence: 0),
            ZenzaiTypoCandidate(correctedInput: "おはようございます", convertedText: "おはようございます", score: 0, lmScore: 0, channelCost: 2.0, prominence: 0),
        ]
        let readings = SegmentsManager.filterGenuineTypoCorrectionReadings(candidates)
        #expect(readings == ["おはようございます"])
    }

    /// Backspace の KanaFuzzyRepair カスケードでは、隣接キー仮説により入力側の訂正は
    /// 既に完了しているため、LM 側が無編集（channelCost == 0）で到達した候補も
    /// 正当な訂正結果として採用されることを確認する（requireChannelEdit: false）。
    @Test func allowsIdentityCandidatesWhenChannelEditNotRequired() {
        let candidates = [
            ZenzaiTypoCandidate(correctedInput: "かめ", convertedText: "かめ", score: 0, lmScore: 0, channelCost: 0, prominence: 0),
        ]
        let readings = SegmentsManager.filterGenuineTypoCorrectionReadings(candidates, requireChannelEdit: false)
        #expect(readings == ["かめ"])
    }
}
