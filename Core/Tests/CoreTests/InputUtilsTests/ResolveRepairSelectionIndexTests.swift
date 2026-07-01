@testable import Core
import Testing

/// `azooKeyMacInputController` の修復候補 completion handler が使う
/// `resolveRepairSelectionIndex` の単体テスト。修復候補が先頭に昇格し候補配列の並びが
/// 変わっても、以前選択していたのと同じ論理候補を新配列上で正しく指し続けることを確認する。
@Suite struct ResolveRepairSelectionIndexTests {
    @Test func followsSameCandidateAfterPromotionShiftsItBack() {
        let old = ["おめ", "重め"]
        let new = ["亀", "重め", "おめ"]
        let result = resolveRepairSelectionIndex(
            oldCandidateTexts: old,
            oldSelectionIndex: 0,
            newCandidateTexts: new,
            serverSelectionIndex: 2
        )
        #expect(result == 2)
    }

    @Test func fallsBackToServerIndexWhenCandidateDisappears() {
        let old = ["おめ"]
        let new = ["亀", "重め"]
        let result = resolveRepairSelectionIndex(
            oldCandidateTexts: old,
            oldSelectionIndex: 0,
            newCandidateTexts: new,
            serverSelectionIndex: 1
        )
        #expect(result == 1)
    }

    @Test func fallsBackToServerIndexWhenOldSelectionIsNil() {
        let result = resolveRepairSelectionIndex(
            oldCandidateTexts: ["おめ"],
            oldSelectionIndex: nil,
            newCandidateTexts: ["亀"],
            serverSelectionIndex: 0
        )
        #expect(result == 0)
    }

    @Test func fallsBackToServerIndexWhenOldSelectionOutOfRange() {
        let result = resolveRepairSelectionIndex(
            oldCandidateTexts: ["おめ"],
            oldSelectionIndex: 5,
            newCandidateTexts: ["亀"],
            serverSelectionIndex: 0
        )
        #expect(result == 0)
    }

    /// 追加候補（ひらがな変換など）と通常候補が同じテキストになる場合、
    /// 選択中だった側（同じ occurrence）を正しく追従できることを確認する。
    @Test func distinguishesDuplicateTextByOccurrenceAcrossAdditionalCandidates() {
        let old = ["おめ", "おめ"]
        let new = ["おめ", "亀", "おめ"]
        let result = resolveRepairSelectionIndex(
            oldCandidateTexts: old,
            oldSelectionIndex: 1,
            newCandidateTexts: new,
            serverSelectionIndex: 2
        )
        #expect(result == 2)
    }
}
