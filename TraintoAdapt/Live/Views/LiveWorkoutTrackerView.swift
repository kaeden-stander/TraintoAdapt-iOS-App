import SwiftUI
import HealthKit

struct LiveWorkoutTrackerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WorkoutTrackerViewModel()
    @State private var selectedActivityRawValue: UInt = HKWorkoutActivityType.traditionalStrengthTraining.rawValue

    private var selectedActivity: HKWorkoutActivityType {
        HKWorkoutActivityType(rawValue: selectedActivityRawValue) ?? .traditionalStrengthTraining
    }

    var body: some View {
        VStack(spacing: 28) {
            switch viewModel.state {
            case .idle:
                idleContent
            case .running, .paused:
                trackingContent
            case .finished:
                finishedContent
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Font.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .navigationTitle("Track a Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.state == .idle || viewModel.state == .finished {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var idleContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(Font.system(size: 56))
                .foregroundStyle(Color.brandPrimary)

            Picker("Activity", selection: $selectedActivityRawValue) {
                ForEach(WorkoutTrackerViewModel.trackableActivities, id: \.rawValue) { activity in
                    Text(activity.displayName).tag(activity.rawValue)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)

            Button {
                viewModel.activityType = selectedActivity
                viewModel.start()
            } label: {
                Text("Start Workout")
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brandPrimary)
            .controlSize(.large)

            Text("Saves to Apple Health when you finish — no Apple Watch needed.")
                .font(Font.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var trackingContent: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(viewModel.activityType.displayName)
                .font(Font.title2.bold())
                .foregroundStyle(Color.brandPrimary)

            Text(elapsedString)
                .font(Font.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()

            if viewModel.state == .paused {
                Text("Paused")
                    .font(Font.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    if viewModel.state == .running {
                        viewModel.pause()
                    } else {
                        viewModel.resume()
                    }
                } label: {
                    Label(viewModel.state == .running ? "Pause" : "Resume", systemImage: viewModel.state == .running ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .tint(Color.brandSecondary)
                .controlSize(.large)

                Button {
                    Task { await viewModel.finish() }
                } label: {
                    if viewModel.isSaving {
                        ProgressView().tint(.black).frame(maxWidth: .infinity)
                    } else {
                        Text("Finish")
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandPrimary)
                .controlSize(.large)
                .disabled(viewModel.isSaving)
            }

            Button("Discard Workout", role: .destructive) {
                viewModel.discardAndReset()
            }
            .font(Font.footnote)
        }
    }

    private var finishedContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(Font.system(size: 56))
                .foregroundStyle(.green)

            Text("Workout Saved")
                .font(Font.title2.bold())

            Text("\(viewModel.activityType.displayName) · \(elapsedString)")
                .font(Font.subheadline)
                .foregroundStyle(.secondary)

            Text("This is now in Apple Health, along with anything synced from your Apple Watch.")
                .font(Font.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brandPrimary)
            .controlSize(.large)
            .padding(.top, 8)
        }
    }

    private var elapsedString: String {
        let total = Int(viewModel.elapsed)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
