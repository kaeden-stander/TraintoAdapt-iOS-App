import SwiftUI

struct MealPlanView: View {
    let client: User
    @StateObject private var viewModel: MealPlanViewModel

    init(client: User) {
        self.client = client
        _viewModel = StateObject(wrappedValue: MealPlanViewModel(clientID: client.id))
    }

    var body: some View {
        Group {
            if let plan = viewModel.mealPlan {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        planHeader(plan)
                        macroSummary(plan)

                        ForEach(viewModel.mealsGrouped, id: \.type) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Label(group.type.rawValue, systemImage: group.type.systemImage)
                                    .font(Font.headline)
                                    .padding(.horizontal)

                                VStack(spacing: 0) {
                                    ForEach(group.meals) { meal in
                                        MealRow(meal: meal)
                                        if meal.id != group.meals.last?.id {
                                            Divider().padding(.leading, 16)
                                        }
                                    }
                                }
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                                .padding(.horizontal)
                            }
                        }

                        if let notes = plan.notes {
                            SectionCard(title: "Coach Notes") {
                                Text(notes).font(Font.subheadline)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            } else if viewModel.isLoading {
                ProgressView()
            } else {
                EmptyStateRow(
                    systemImage: "fork.knife.circle",
                    message: "Your trainer hasn't set up a meal plan yet."
                )
            }
        }
        .navigationTitle("Meal Plan")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private func planHeader(_ plan: MealPlan) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(plan.title).font(Font.title2.bold())
            Text("\(plan.startDate.formatted(date: .abbreviated, time: .omitted))" +
                 (plan.endDate.map { " – \($0.formatted(date: .abbreviated, time: .omitted))" } ?? ""))
                .font(Font.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private func macroSummary(_ plan: MealPlan) -> some View {
        SectionCard(title: "Daily Targets") {
            HStack {
                MacroStat(label: "Calories", value: "\(plan.dailyCalorieTarget)", unit: "kcal")
                Spacer()
                MacroStat(label: "Protein", value: "\(plan.proteinTargetGrams)", unit: "g")
                Spacer()
                MacroStat(label: "Carbs", value: "\(plan.carbsTargetGrams)", unit: "g")
                Spacer()
                MacroStat(label: "Fat", value: "\(plan.fatTargetGrams)", unit: "g")
            }
        }
        .padding(.horizontal)
    }
}

private struct MealRow: View {
    let meal: Meal

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name).font(Font.subheadline.weight(.medium))
                Text("P \(meal.proteinGrams)g · C \(meal.carbsGrams)g · F \(meal.fatGrams)g")
                    .font(Font.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(meal.calories) kcal")
                .font(Font.caption.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
        }
        .padding()
    }
}

private struct MacroStat: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(Font.title3.bold())
            Text(unit).font(Font.caption2).foregroundStyle(.secondary)
            Text(label).font(Font.caption).foregroundStyle(.secondary)
        }
    }
}
