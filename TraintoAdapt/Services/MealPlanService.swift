import Foundation

protocol MealPlanServiceProtocol {
    func currentMealPlan(forClient clientID: UUID) async -> MealPlan?
    func mealPlans(forClient clientID: UUID) async -> [MealPlan]
    func mealPlans(createdByTrainer trainerID: UUID) async -> [MealPlan]
    @discardableResult
    func saveMealPlan(_ plan: MealPlan) async throws -> MealPlan
    func deleteMealPlan(_ planID: UUID) async throws
}

@MainActor
final class MockMealPlanService: MealPlanServiceProtocol {
    private let store: MockDataStore

    init(store: MockDataStore = .shared) {
        self.store = store
    }

    func currentMealPlan(forClient clientID: UUID) async -> MealPlan? {
        store.mealPlans
            .filter { $0.clientID == clientID }
            .sorted { $0.startDate > $1.startDate }
            .first
    }

    func mealPlans(forClient clientID: UUID) async -> [MealPlan] {
        store.mealPlans
            .filter { $0.clientID == clientID }
            .sorted { $0.startDate > $1.startDate }
    }

    func mealPlans(createdByTrainer trainerID: UUID) async -> [MealPlan] {
        store.mealPlans
            .filter { $0.createdByTrainerID == trainerID }
            .sorted { $0.startDate > $1.startDate }
    }

    @discardableResult
    func saveMealPlan(_ plan: MealPlan) async throws -> MealPlan {
        if let index = store.mealPlans.firstIndex(where: { $0.id == plan.id }) {
            store.mealPlans[index] = plan
        } else {
            store.mealPlans.append(plan)
        }
        return plan
    }

    func deleteMealPlan(_ planID: UUID) async throws {
        store.mealPlans.removeAll { $0.id == planID }
    }
}
