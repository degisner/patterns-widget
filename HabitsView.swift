import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    @Query private var habits: [Habit]
    let habitsNumber: Int
    let width: CGFloat
    
    init(habitsNumber: Int, width: CGFloat) {
        self._habits = Query(filter: #Predicate<Habit> { $0.order < habitsNumber }, sort: \.order)
        self.habitsNumber = habitsNumber
        self.width = width
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< habitsNumber, id: \.self) { index in
                if habits.indices.contains(index) {
                    let habit = habits[index]
                    
                    if habit.order != 0 {
                        Spacer(minLength: 0)
                    }
                    
                    rowView(habit: habit, width: width)
                } else {
                    Rectangle().fill(.backgroundWidget)
                        .frame(height: size)
                }
            }
        }
        .padding(.vertical, padding)
    }
    
    func rowView(habit: Habit, width: CGFloat) -> some View {
        HStack(spacing: 0) {
            Text(habit.icon)
                .font(font)
                .fixedSize(horizontal: true, vertical: false)
            
            Spacer(minLength: 0)
            
            LogsView(habit: habit, logsNumber: 11 - indexesStart, width: size)
        }
        .padding(.horizontal, padding)
    }
    
    // Small widget width:
    // iPhone Mini's width is 155
    // iPhone 15 Pro's width is 158
    // iPhone 15 Pro Max's width is 170
    //
    // Medium & Large widget width:
    // iPhone Mini's width is 329
    // iPhone 15 Pro's width is 338
    // iPhone 15 Pro Max's width is 364
    var size: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            switch width {
            case ..<156: return 24
            case ..<160: return 26
            default:     return 28
            }
        default:
            switch width {
            case ..<335: return 24.5
            case ..<350: return 25.75
            default:     return 27.6
            }
        }
    }
    
    var indexesStart: Int {
        switch widgetFamily {
        case .systemSmall: return 7
        default:           return width < 335 ? 1 : 0
        }
    }
    
    var padding: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            switch width {
            case ..<156: return 10
            case ..<160: return 14
            default:     return 15
            }
        case .systemMedium:
            switch width {
            case ..<335: return 10
            case ..<350: return 14
            default:     return 16
            }
        default:
            switch width {
            case ..<335: return 11
            case ..<350: return 14
            default:     return 16
            }
        }
    }
    
    var font: Font {
        switch widgetFamily {
        case .systemSmall: return width < 156 ? .footnote : .subheadline
        default:           return width < 335 ? .footnote : .subheadline
        }
    }
}
