import SwiftUI
import SwiftData

struct LogsView: View {
    @Query private var logs: [Log]
    let habit: Habit
    let logsNumber: Int
    let width: CGFloat
    
    init(habit: Habit, logsNumber: Int, width: CGFloat) {
        let habitName = habit.name
        let firstDate = Date.now.reset(after: .day).byAdding(.day, value: -logsNumber)
        self._logs = Query(filter: #Predicate<Log> { $0.habit?.name == habitName && $0.date > firstDate }, sort: \.date)
        self.habit = habit
        self.logsNumber = logsNumber
        self.width = width
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(-(logsNumber - 1) ... 0, id: \.self) { i in
                let exists = logs.contains { $0.date.isDate(Date().byAdding(.day, value: i)) }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .foregroundStyle(habit.color.asColor)
                        .opacity(exists ? 0.3 : 0.2)
                    
                    Button(intent: LogIntent(habitID: habit.order, logID: i)) {
                        Rectangle()
                            .foregroundStyle(.backgroundWidget)
                    }
                    .buttonStyle(.borderless)
                    
                    RoundedRectangle(cornerRadius: exists ? 4 : 7, style: .continuous)
                        .foregroundStyle(habit.color.asColor)
                        .frame(width: 14, height: 14)
                        .scaleEffect(exists ? 1 : 0.6)
                        .opacity(exists ? 1 : 0.3)
                }
                .frame(width: width, height: width)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: exists)
            }
        }
    }
}
