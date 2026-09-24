import SwiftUI

/// Shows activity and workout data pulled from HealthKit. On a device with a
/// paired Apple Watch, Health already syncs Watch data automatically, so
/// this view is effectively the "Watch data" screen without needing its own
/// WatchConnectivity session.
struct HealthSummaryView: View {
    @StateObject private var viewModel = HealthViewModel()

    var body: some View {
        List {
            if !viewModel.isHealthDataAvailable {
                Section {
                    EmptyStateRow(systemImage: "xmark.circle", message: "Health data isn't available on this device.")
                }
            } else if !viewModel.isAuthorized {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Connect Apple Health")
                            .font(Font.headline)
                        Text("Grant access to read steps, heart rate, active energy and workouts. If you wear an Apple Watch, this data syncs in automatically.")
                            .font(Font.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            Task { await viewModel.connect() }
                        } label: {
                            Label("Connect", systemImage: "applewatch")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 8)
                }
            } else {
                Section("Today") {
                    HealthSummaryRow(summary: viewModel.summary)
                        .padding(.vertical, 4)
                }

                Section("Recent Workouts") {
                    if viewModel.recentWorkouts.isEmpty {
                        EmptyStateRow(systemImage: "figure.run", message: "No workouts synced yet.")
                    } else {
                        ForEach(viewModel.recentWorkouts) { workout in
                            WorkoutRow(workout: workout)
                        }
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Health & Activity")
        .task {
            if viewModel.isAuthorized {
                await viewModel.refresh()
            }
        }
        .refreshable { await viewModel.refresh() }
    }
}

struct HealthSummaryRow: View {
    let summary: DailyHealthSummary

    var body: some View {
        HStack(spacing: 0) {
            HealthStat(systemImage: "figure.walk", value: "\(summary.steps)", label: "Steps")
            Spacer()
            HealthStat(systemImage: "flame.fill", value: "\(Int(summary.activeEnergyKcal))", label: "kcal")
            Spacer()
            HealthStat(
                systemImage: "heart.fill",
                value: summary.averageHeartRate.map { "\(Int($0))" } ?? "—",
                label: "Avg HR"
            )
            Spacer()
            HealthStat(systemImage: "stopwatch.fill", value: "\(summary.exerciseMinutes)", label: "Ex. min")
        }
    }
}

private struct HealthStat: View {
    let systemImage: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.brandPrimary)
            Text(value).font(Font.headline)
            Text(label).font(Font.caption2).foregroundStyle(.secondary)
        }
    }
}

private struct WorkoutRow: View {
    let workout: WorkoutSample

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.activityName).font(Font.subheadline.weight(.medium))
                Text(workout.start.formatted(date: .abbreviated, time: .shortened))
                    .font(Font.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(workout.durationMinutes) min").font(Font.caption)
                if let energy = workout.totalEnergyKcal {
                    Text("\(Int(energy)) kcal").font(Font.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}
