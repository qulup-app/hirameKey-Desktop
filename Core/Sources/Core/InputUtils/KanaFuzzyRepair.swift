import KanaKanjiConverterModuleWithDefaultDictionary

/// キー配列の隣接キー置換によるタイポ修復候補を生成する。
/// ローマ字入力（QWERTY）とかな直接入力（JIS かな配列）の両方に対応する。
enum KanaFuzzyRepair {

    // MARK: - ローマ字入力（QWERTY）

    // 標準 QWERTY の隣接キー対応表（小文字 ASCII のみ）
    private static let romajiNeighbors: [Character: [Character]] = [
        "q": ["w", "a", "s"],
        "w": ["q", "e", "a", "s", "d"],
        "e": ["w", "r", "s", "d", "f"],
        "r": ["e", "t", "d", "f", "g"],
        "t": ["r", "y", "f", "g", "h"],
        "y": ["t", "u", "g", "h", "j"],
        "u": ["y", "i", "h", "j", "k"],
        "i": ["u", "o", "j", "k", "l"],
        "o": ["i", "p", "k", "l"],
        "p": ["o", "l"],
        "a": ["q", "w", "s", "z"],
        "s": ["a", "w", "e", "d", "z", "x"],
        "d": ["s", "e", "r", "f", "x", "c"],
        "f": ["d", "r", "t", "g", "c", "v"],
        "g": ["f", "t", "y", "h", "v", "b"],
        "h": ["g", "y", "u", "j", "b", "n"],
        "j": ["h", "u", "i", "k", "n", "m"],
        "k": ["j", "i", "o", "l", "m"],
        "l": ["k", "o", "p"],
        "z": ["a", "s", "x"],
        "x": ["z", "s", "d", "c"],
        "c": ["x", "d", "f", "v"],
        "v": ["c", "f", "g", "b"],
        "b": ["v", "g", "h", "n"],
        "n": ["b", "h", "j", "m"],
        "m": ["n", "j", "k"]
    ]

    /// ローマ字の各文字を QWERTY 隣接キーで置換した代替文字列を返す。
    /// 位置横断ラウンドロビンで生成する。pass 0 は全位置を必ずカバーするため
    /// maxCount より入力長が長い場合は入力長を実効上限とする。
    static func romajiHypotheses(for romaji: String, maxCount: Int = 18) -> [String] {
        let chars = Array(romaji.lowercased())
        let neighbors = chars.map { romajiNeighbors[$0] ?? [] }
        let maxPass = neighbors.map(\.count).max() ?? 0
        // pass 0 完走に必要な件数を下限にして全位置をカバーする
        let eligibleCount = neighbors.filter { !$0.isEmpty }.count
        let effectiveMax = max(maxCount, eligibleCount)
        var results: [String] = []
        for pass in 0..<maxPass {
            for i in chars.indices {
                guard pass < neighbors[i].count else { continue }
                var alt = chars
                alt[i] = neighbors[i][pass]
                results.append(String(alt))
                // pass 1 以降は append ごとに上限チェック（pass 0 は全位置を完走させる）
                if pass > 0, results.count >= effectiveMax { break }
            }
            if results.count >= effectiveMax { break }
        }
        return results
    }

    // MARK: - かな直接入力（JIS かな配列）

    // JIS かな配列: [row][col] = (非シフト, シフト or nil)
    // Row 0: 数字キー列, Row 1: Q列, Row 2: A列, Row 3: Z列
    private static let jisLayout: [[(main: Character, shift: Character?)]] = [
        // Row 0: 1  2   3          4          5          6          7          8          9          0     -      ^
        [("ぬ", nil), ("ふ", nil), ("あ", "ぁ"), ("う", "ぅ"), ("え", "ぇ"), ("お", "ぉ"), ("や", "ゃ"), ("ゆ", "ゅ"), ("よ", "ょ"), ("わ", "ゎ"), ("ほ", nil), ("へ", nil)],
        // Row 1: Q    W    E          R    T    Y    U    I    O    P    [    ]
        [("た", nil), ("て", nil), ("い", "ぃ"), ("す", nil), ("か", nil), ("ん", nil), ("な", nil), ("に", nil), ("ら", nil), ("せ", nil), ("゛", nil), ("゜", nil)],
        // Row 2: A    S    D    F    G    H    J    K    L    ;    :
        [("ち", nil), ("と", nil), ("し", nil), ("は", nil), ("き", nil), ("く", nil), ("ま", nil), ("の", nil), ("り", nil), ("れ", nil), ("け", nil)],
        // Row 3: Z    X    C    V    B    N    M    ,    .    /
        [("つ", "っ"), ("さ", nil), ("そ", nil), ("ひ", nil), ("こ", nil), ("み", nil), ("も", nil), ("ね", nil), ("る", nil), ("め", nil), ("ろ", nil)]
    ]

    // 濁点・半濁点の関係（打ち間違いとして扱う）
    // ponytail: 双方向に定義せず、代わりに lookup 時に逆引きも行う
    private static let dakutenVariants: [Character: [Character]] = [
        "か": ["が"], "き": ["ぎ"], "く": ["ぐ"], "け": ["げ"], "こ": ["ご"],
        "さ": ["ざ"], "し": ["じ"], "す": ["ず"], "せ": ["ぜ"], "そ": ["ぞ"],
        "た": ["だ"], "ち": ["ぢ"], "つ": ["づ"], "て": ["で"], "と": ["ど"],
        "は": ["ば", "ぱ"], "ひ": ["び", "ぴ"], "ふ": ["ぶ", "ぷ"],
        "へ": ["べ", "ぺ"], "ほ": ["ぼ", "ぽ"],
        "う": ["ゔ"],
        "が": ["か"], "ぎ": ["き"], "ぐ": ["く"], "げ": ["け"], "ご": ["こ"],
        "ざ": ["さ"], "じ": ["し"], "ず": ["す"], "ぜ": ["せ"], "ぞ": ["そ"],
        "だ": ["た"], "ぢ": ["ち"], "づ": ["つ"], "で": ["て"], "ど": ["と"],
        "ば": ["は", "ぱ"], "び": ["ひ", "ぴ"], "ぶ": ["ふ", "ぷ"],
        "べ": ["へ", "ぺ"], "ぼ": ["ほ", "ぽ"],
        "ぱ": ["は", "ば"], "ぴ": ["ひ", "び"], "ぷ": ["ふ", "ぶ"],
        "ぺ": ["へ", "べ"], "ぽ": ["ほ", "ぼ"],
        "ゔ": ["う"]
    ]

    // キャラクタ → (row, col) の逆引きマップ（初回アクセス時に構築）
    private static let jisPositionMap: [Character: (row: Int, col: Int)] = {
        var map: [Character: (row: Int, col: Int)] = [:]
        for (row, cols) in jisLayout.enumerated() {
            for (col, (main, shift)) in cols.enumerated() {
                map[main] = (row, col)
                if let s = shift { map[s] = (row, col) }
            }
        }
        return map
    }()

    /// JIS かな配列上で物理的に隣接するかな文字を返す。
    /// 濁点・半濁点の variant も隣接として扱う。
    static func jisKanaNeighbors(for c: Character) -> [Character] {
        var result: [Character] = []

        if let pos = jisPositionMap[c] {
            // 物理的に隣接するキーのかな
            for dr in -1...1 {
                for dc in -1...1 {
                    guard dr != 0 || dc != 0 else { continue }
                    let nr = pos.row + dr
                    let nc = pos.col + dc
                    guard nr >= 0, nr < jisLayout.count,
                          nc >= 0, nc < jisLayout[nr].count else { continue }
                    let (main, shift) = jisLayout[nr][nc]
                    // ゛゜ は変換対象外
                    if main != "゛" && main != "゜" { result.append(main) }
                    if let s = shift { result.append(s) }
                }
            }
            // 同一キーのシフト variant（あ ↔ ぁ、つ ↔ っ など）
            let (main, shift) = jisLayout[pos.row][pos.col]
            if c == main, let s = shift { result.append(s) }
            else if shift == c { result.append(main) }
        }

        // 濁点・半濁点 variant
        if let variants = dakutenVariants[c] {
            result.append(contentsOf: variants)
        }

        return result.filter { $0 != c }
    }

    /// かな文字列の各文字を JIS かな隣接キーで置換した代替文字列を返す。
    /// 位置横断ラウンドロビンで生成する。pass 0 は全位置を必ずカバーするため
    /// maxCount より入力長が長い場合は入力長を実効上限とする。
    static func kanaHypotheses(for kana: String, maxCount: Int = 18) -> [String] {
        let chars = Array(kana)
        let neighbors = chars.map { jisKanaNeighbors(for: $0) }
        let maxPass = neighbors.map(\.count).max() ?? 0
        // pass 0 完走に必要な件数を下限にして全位置をカバーする
        let eligibleCount = neighbors.filter { !$0.isEmpty }.count
        let effectiveMax = max(maxCount, eligibleCount)
        var results: [String] = []
        for pass in 0..<maxPass {
            for i in chars.indices {
                guard pass < neighbors[i].count else { continue }
                var alt = chars
                alt[i] = neighbors[i][pass]
                results.append(String(alt))
                // pass 1 以降は append ごとに上限チェック（pass 0 は全位置を完走させる）
                if pass > 0, results.count >= effectiveMax { break }
            }
            if results.count >= effectiveMax { break }
        }
        return results
    }

    // MARK: - 共通

    /// 候補のテキストが入力かなと一致する（辞書ヒットなしのフォールバック）かどうか判定する。
    static func isFallback(_ candidate: Candidate, convertTarget: String) -> Bool {
        candidate.text.toHiragana() == convertTarget.toHiragana()
    }
}
