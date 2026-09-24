import SwiftUI

struct TrainerClientDetailView: View {
    let trainer: User
    let client: User

    @StateObject private var bookingViewModel: BookingViewModel
    @StateObject private var mealPlanViewModel: MealPlanViewModel
    @State private var showingMealPlanEditor = false

    init(trainer: User, client: User) {
        self.trainer = trainer
        self.client = client
        _bookingViewModel = StateObject(wrappedValue: BookingViewModel(clientID: client.id))
        _mealPlanViewModel = StateObject(wrappedValue: MealPlanViewModel(clientID: client.id))
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    InitialsAvatar(initials: client.initials)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.fullName).font(Font.headline)
                        Text(client.email).font(Font.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Sessions") {
                if bookingViewModel.upcomingBookings.isEmpty {
                    Text("No upcoming sessions.").foregroundStyle(.secondary)
                } else {
                    ForEach(bookingViewModel.upcomingBookings) { booking in
                        BookingRow(booking: booking, trainerName: trainer.fullName)
                    }
                }
            }

            Section("Meal Plan") {
                if let plan = mealPlanViewModel.mealPlan {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title).font(Font.subheadline.weight(.medium))
                        Text("\(plan.dailyCalorieTarget) kcal/day target")
                            .font(Font.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No meal plan assigned yet.").foregroundStyle(.secondary)
                }

                Button {
                    showingMealPlanEditor = true
                } label: {
                    Label(mealPlanViewModel.mealPlan == nil ? "Create Meal Plan" : "Edit Meal Plan", systemImage: "pencil")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(client.firstName)
        .sheet(isPresented: $showingMealPlanEditor, onDismiss: {
            Task { await mealPlanViewModel.load() }
        }) {
            NavigationStack {
                TrainerMealPlanEditorView(trainer: trainer, client: client, existingPlan: mealPlanViewModel.mealPlan)
            }
        }
        .task {
            await bookingViewModel.load()
            await mealPlanViewModel.load()
        }
    }
}
