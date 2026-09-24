import SwiftUI

struct TrainerMealPlanEditorView: View {
    let trainer: User
    let client: User
    let existingPlan: MealPlan?

    @Environment(\.dismiss) private var dismiss
    private let service: MealPlanServiceProtocol = MockMealPlanService()

    @State private var title: String
    @State private var calorieTarget: Int
    @State private var proteinTarget: Int
    @State private var carbsTarget: Int
    @State private var fatTarget: Int
    @State private var notes: String
    @State private var meals: [Meal]
    @State private var isSaving = false

    init(trainer: User, client: User, existingPlan: MealPlan?) {
        self.trainer = trainer
        self.client = client
        self.existingPlan = existingPlan
        _title = State(initialValue: existingPlan?.title ?? "\(client.firstName)'s Meal Plan")
        _calorieTarget = State(initialValue: existingPlan?.dailyCalorieTarget ?? 2200)
        _proteinTarget = State(initialValue: existingPlan?.proteinTargetGrams ?? 150)
        _carbsTarget = State(initialValue: existingPlan?.carbsTargetGrams ?? 220)
        _fatTarget = State(initialValue: existingPlan?.fatTargetGrams ?? 70)
        _notes = State(initialValue: existingPlan?.notes ?? "")
        _meals = State(initialValue: existingPlan?.meals ?? [])
    }

    var body: some View {
        Form {
            Section("Plan") {
                TextField("Title", text: $title)
            }

            Section("Daily Targets") {
                Stepper("Calories: \(calorieTarget) kcal", value: $calorieTarget, in: 1200...5000, step: 50)
                Stepper("Protein: \(proteinTarget) g", value: $proteinTarget, in: 20...400, step: 5)
                Stepper("Carbs: \(carbsTarget) g", value: $carbsTarget, in: 20...600, step: 5)
                Stepper("Fat: \(fatTarget) g", value: $fatTarget, in: 10...200, step: 5)
            }

            Section("Meals") {
                ForEach(meals) { meal in
                    VStack(alignment: .leading) {
                        Text(meal.name).font(.subheadline.weight(.medium))
                        Text("\(meal.type.rawValue) · \(meal.calories) kcal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    meals.remove(atOffsets: indexSet)
                }

                Button {
                    meals.append(Meal(name: "New meal", type: .snack, calories: 200, proteinGrams: 15, carbsGrams: 20, fatGrams: 6))
                } label: {
                    Label("Add Meal", systemImage: "plus")
                }
            }

            Section("Notes for client") {
                TextField("Guidance, reminders...", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(existingPlan == nil ? "New Meal Plan" : "Edit Meal Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(isSaving || title.isEmpty)
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let plan = MealPlan(
            id: existingPlan?.id ?? UUID(),
            clientID: client.id,
            createdByTrainerID: trainer.id,
            title: title,
            startDate: existingPlan?.startDate ?? .now,
            endDate: existingPlan?.endDate,
            dailyCalorieTarget: calorieTarget,
            proteinTargetGrams: proteinTarget,
            carbsTargetGrams: carbsTarget,
            fatTargetGrams: fatTarget,
            meals: meals,
            notes: notes.isEmpty ? nil : notes
        )
        _ = try? await service.saveMealPlan(plan)
        dismiss()
    }
}
