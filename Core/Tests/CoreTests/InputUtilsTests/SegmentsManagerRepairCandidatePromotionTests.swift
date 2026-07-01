@testable import Core
import Foundation
import KanaKanjiConverterModuleWithDefaultDictionary
import Testing

private func makeSegmentsManager() -> SegmentsManager {
    SegmentsManager(
        kanaKanjiConverter: .withDefaultDictionary(),
        applicationDirectoryURL: URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true),
        containerURL: nil,
        context: .init(useZenzai: false)
    )
}

/// 修復候補が先頭に昇格した際、選択中だった候補を selectionIndex が正しく追従することを確認する。
/// 「おめ」は辞書ヒットなし（かな読み直返し）だが、JIS かな配列上で隣接する「かめ」への
/// 修復候補が辞書変換され、先頭に昇格する対象になる。
@MainActor
@Test func repairCandidatePromotionKeepsSelectionOnPreviouslySelectedCandidate() async throws {
    let defaults = Config.userDefaults
    let key = Config.KanaFuzzyRepair.key
    let originalData = defaults.data(forKey: key)
    defer {
        if let data = originalData {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
    Config.KanaFuzzyRepair().value = true

    let manager = makeSegmentsManager()
    manager.insertAtCursorPosition("おめ", inputStyle: .direct)
    manager.requestSetCandidateWindowState(visible: true)

    guard case .selecting(let baseCandidates, let baseIdx) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
        Issue.record("expected .selecting state before repair")
        return
    }
    // 修復前は辞書ヒットなし（かな読み直返し）が選択された状態になっている。
    try #require(baseIdx == 0)
    let selectedCandidateText = baseCandidates[0].text
    #expect(selectedCandidateText.toHiragana() == "おめ".toHiragana())

    manager.updateRepairCandidates()

    guard case .selecting(let candidates, let selectionIndex) = manager.getCurrentCandidateWindow(inputState: .selecting) else {
        Issue.record("expected .selecting state after repair")
        return
    }
    let newIndex = try #require(selectionIndex)

    // 修復候補が先頭に昇格し、以前選択していた候補は後方にずれる。
    #expect(candidates.first?.text != selectedCandidateText)
    #expect(newIndex > 0)
    // ずれた後も selectionIndex は同じ候補（かな読み直返し）を指し続ける。
    #expect(candidates[newIndex].text == selectedCandidateText)
}
