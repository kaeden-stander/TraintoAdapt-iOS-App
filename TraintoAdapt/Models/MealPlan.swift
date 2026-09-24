import Foundation

struct MealPlan: Identifiable, Codable, Hashable {
    let id: UUID
    var clientID: UUID
    var createdByTrainerID: UUID
    var title: String
    var startDate: Date
    var endDate: Date?
    var dailyCalorieTarget: Int
    var proteinTargetGrams: Int
    var carbsTargetGrams: Int
    var fatTargetGrams: Int
    var meals: [Meal]
    var notes: String?

    init(
        id: UUID = UUID(),
        clientID: UUID,
        createdByTrainerID: UUID,
        title: String,
        startDate: Date = .now,
        endDate: Date? = nil,
        dailyCalorieTarget: Int,
        proteinTargetGrams: Int,
        carbsTargetGrams: Int,
        fatTargetGrams: Int,
        meals: [Meal] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.clientID = clientID
        self.createdByTrainerID = createdByTrainerID
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.dailyCalorieTarget = dailyCalorieTarget
        self.proteinTargetGrams = proteinTargetGrams
        self.carbsTargetGrams = carbsTargetGrams
        self.fatTargetGrams = fatTargetGrams
        self.meals = meals
        self.notes = notes
    }

    var mealsByType: [MealType: [Meal]] {
        Dictionary(grouping: meals, by: \.type)
    }
}

struct Meal: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var type: MealType
    var calories: Int
    var proteinGrams: Int
    var carbsGrams: Int
    var fatGrams: Int
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        type: MealType,
        calories: Int,
        proteinGrams: Int,
        carbsGrams: Int,
        fatGrams: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.notes = notes
    }
}

enum MealType: String, Codable, CaseIterable, Identifiable, Hashable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .breakfast: 0
        case .lunch: 1
        case .dinner: 2
        case .snack: 3
        }
    }

    var systemImage: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .snack: "leaf.fill"
        }
    }
}
