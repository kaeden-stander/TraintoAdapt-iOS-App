import Foundation

@MainActor
final class MealPlanViewModel: ObservableObject {
    @Published var mealPlan: MealPlan?
    @Published var isLoading = false

    private let service: MealPlanServiceProtocol
    private let clientID: UUID

    init(clientID: UUID, service: MealPlanServiceProtocol? = nil) {
        self.clientID = clientID
        self.service = service ?? MockMealPlanService()
    }

    var mealsGrouped: [(type: MealType, meals: [Meal])] {
        guard let mealPlan else { return [] }
        return MealType.allCases
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { type in
                let meals = mealPlan.meals.filter { $0.type == type }
                return meals.isEmpty ? nil : (type, meals)
            }
    }

    var totalCalories: Int {
        mealPlan?.meals.reduce(0) { $0 + $1.calories } ?? 0
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        mealPlan = await service.currentMealPlan(forClient: clientID)
    }
}
