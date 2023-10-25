import SwiftUI
import SwiftData
import AVFoundation

struct Row: Identifiable {
    var id: Int
    var icon: String
    var color: Color
    var items: [Item]
    
    init(id: Int, icon: String, color: Color, items: [Item] = []) {
        self.id = id
        self.icon = icon
        self.color = color
        self.items = items
    }
}

struct Item: Identifiable {
    var id: Int
    var isLogged: Bool
}

class GridWidgetViewModel: ObservableObject {
    static let shared = GridWidgetViewModel()
    
    @MainActor
    func getRows() -> [Row] {
        do {
            let habitsDescriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.order < 12 }, sortBy: [SortDescriptor(\Habit.order)])
            let habits = try modelContainer.mainContext.fetch(habitsDescriptor)
            var rows = habits.map { Row(id: $0.order, icon: $0.icon, color: $0.color.asColor) }
            
            for habit in habits {
                let habitName = habit.name
                let firstDate = Date().reset(after: .day).byAdding(.day, value: -11)
                let logDescriptor = FetchDescriptor<Log>(
                    predicate: #Predicate { $0.habit?.name == habitName && $0.date > firstDate },
                    sortBy: [SortDescriptor(\Log.date)]
                )
                
                let logs = try modelContainer.mainContext.fetch(logDescriptor)
                
                var items: [Item] = []
                
                for i in 0 ..< 11 {
                    let date = Date().reset(after: .day).byAdding(.day, value: i - 10)
                    let contains = logs.map { $0.date }.contains(date)
                    let item = Item(id: i, isLogged: contains)
                    items.append(item)
                }
                
                if rows.indices.contains(habit.order) {
                    rows[habit.order].items = items
                }
            }
            
            return rows
        } catch {
            print("Error fetching habits in widget. \(error.localizedDescription)")
            return []
        }
    }
    
    @MainActor
    func update(rowID: Int, itemID: Int) {
        do {
            let descriptor = FetchDescriptor<Log>()
            let logs = try modelContainer.mainContext.fetch(descriptor)
            let date = Date().reset(after: .day).byAdding(.day, value: itemID - 10)
            
            if let log = logs.first(where: { $0.habit?.order == rowID && $0.date.isDate(date) }) {
                modelContainer.mainContext.delete(log)
            } else {
                let log = Log(date: date)
                
                let habits = try modelContainer.mainContext.fetch(FetchDescriptor<Habit>())
                if let habit = habits.first(where: { $0.order == rowID }) {
                    log.habit = habit
                }
                
                modelContainer.mainContext.insert(log)
            }
        } catch {
            print("Error updating logs from widget. \(error.localizedDescription)")
        }
    }
}
