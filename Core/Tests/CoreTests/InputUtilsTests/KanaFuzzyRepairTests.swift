@testable import Core
import Testing

// 全位置の第1候補（pass 0）が必ずカバーされることを確認する
@Test func testRomajiHypothesesCoversAllPositions() {
    // 19文字入力: eligibleCount=19 > maxCount=18 → effectiveMax=19 でpass 0が完走する
    let longInput = "nihongohanomoshiroi" // 19文字
    let results = KanaFuzzyRepair.romajiHypotheses(for: longInput, maxCount: 18)

    // 末尾 'i'（位置18）の第1隣接は 'u' → "nihongohanomoshirou" が含まれるはず
    let lastCharAlternative = "nihongohanomoshirou"
    #expect(results.contains(lastCharAlternative), "末尾位置のpass 0候補が含まれていない: \(lastCharAlternative)")
    // effectiveMax = max(18, 19) = 19 件以上返る
    #expect(results.count >= 19)
}

@Test func testRomajiHypothesesShortInput() {
    // 短い入力でも正常動作
    let results = KanaFuzzyRepair.romajiHypotheses(for: "ha")
    #expect(!results.isEmpty)
    // 'h' の第1隣接は 'g' → "ga"
    #expect(results.contains("ga"))
}

@Test func testKanaHypothesesCoversAllPositions() {
    // 20文字入力: eligibleCount=20 > maxCount=18 → effectiveMax=20 でpass 0が完走する
    let longKana = "あいうえおかきくけこさしすせそたちつてと" // 20文字
    let results = KanaFuzzyRepair.kanaHypotheses(for: longKana, maxCount: 18)

    // 末尾 'と'（位置19）の第1隣接は 'た'（row=1,col=0; dr=-1,dc=-1）
    // → "あいうえおかきくけこさしすせそたちつてた"
    let lastCharAlternative = "あいうえおかきくけこさしすせそたちつてた"
    #expect(results.contains(lastCharAlternative), "末尾位置のpass 0候補が含まれていない: \(lastCharAlternative)")
    // effectiveMax = max(18, 20) = 20 件以上返る
    #expect(results.count >= 20)
}

// MARK: - romajiLastCharHypothesis

@Test func testRomajiLastCharHypothesis_shortInput() {
    // "ha": reversed → 末尾 'a'（第1隣接 'q'）が選ばれる → "hq"
    #expect(KanaFuzzyRepair.romajiLastCharHypothesis(for: "ha") == "hq")
}

@Test func testRomajiLastCharHypothesis_selectsLastNotFirst() {
    // "ah": reversed → 末尾 'h'（第1隣接 'g'）が選ばれる → "ag"（先頭 'a' は選ばない）
    #expect(KanaFuzzyRepair.romajiLastCharHypothesis(for: "ah") == "ag")
}

@Test func testRomajiLastCharHypothesis_longInput() {
    // 末尾 'i' の第1隣接は 'u'
    #expect(KanaFuzzyRepair.romajiLastCharHypothesis(for: "nihongohanomoshiroi") == "nihongohanomoshirou")
}

// MARK: - kanaLastCharHypothesis

@Test func testKanaLastCharHypothesis_singleChar() {
    // 'と' の第1隣接は 'た'（row=2,col=1 → dr=-1,dc=-1 → row=1,col=0）
    #expect(KanaFuzzyRepair.kanaLastCharHypothesis(for: "と") == "た")
}

@Test func testKanaLastCharHypothesis_longInput() {
    // 20文字、末尾 'と' の第1隣接は 'た'
    let longKana = "あいうえおかきくけこさしすせそたちつてと"
    #expect(KanaFuzzyRepair.kanaLastCharHypothesis(for: longKana) == "あいうえおかきくけこさしすせそたちつてた")
}

@Test func testKanaLastCharHypothesis_nilForNoEligible() {
    // eligible な文字がなければ nil を返す
    // ゛゜ は隣接なし（eligible でない）
    #expect(KanaFuzzyRepair.kanaLastCharHypothesis(for: "") == nil)
}
