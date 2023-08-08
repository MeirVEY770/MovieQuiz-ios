import Foundation

protocol StatisticService {
    func store(correct count: Int, total amount: Int)
    var totalAccuracy: Double { get }
    var gamesCount: Int { get }
    var bestGame: GameRecord? { get }
}

struct GameRecord: Codable, Comparable {
    let correct: Int
    let total: Int
    let date: Date

    static func < (lhs: GameRecord, rhs: GameRecord) -> Bool {
        if lhs.correct != rhs.correct {
            return lhs.correct < rhs.correct
        } else {
            return lhs.date > rhs.date 
        }
    }

    static func == (lhs: GameRecord, rhs: GameRecord) -> Bool {
        return lhs.correct == rhs.correct && lhs.date == rhs.date
    }
}

final class StatisticServiceImplementation: StatisticService {
    private var gameRecords: [GameRecord] = []
    
    var totalAccuracy: Double {
        if gameRecords.isEmpty {
            return 0.0
        }
        let totalCorrect = gameRecords.reduce(0) { $0 + $1.correct }
        let totalQuestions = gameRecords.reduce(0) { $0 + $1.total }
        return Double(totalCorrect) / Double(totalQuestions)
    }
    
    var gamesCount: Int {
        return gameRecords.count
    }
    
    var bestGame: GameRecord? {
        return gameRecords.max(by: { $0.correct < $1.correct })
    }
    
    func store(correct count: Int, total amount: Int) {
        let gameRecord = GameRecord(correct: count, total: amount, date: Date())
        gameRecords.append(gameRecord)
        saveGameRecords()
    }
    
    private func saveGameRecords() {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(gameRecords) {
            UserDefaults.standard.set(encodedData, forKey: "gameRecords")
        }
    }
    
    private func loadGameRecords() {
        if let data = UserDefaults.standard.data(forKey: "gameRecords") {
            let decoder = JSONDecoder()
            if let decodedRecords = try? decoder.decode([GameRecord].self, from: data) {
                gameRecords = decodedRecords
            }
        }
    }
    
    init() {
        loadGameRecords()
    }
}
