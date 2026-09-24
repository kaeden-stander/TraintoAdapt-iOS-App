import SwiftUI

struct LiveHomeView: View {
    @ObservedObject var session: LiveSessionStore
    @StateObject private var bookingViewModel: LiveBookingViewModel
    @StateObject private var healthViewModel = HealthViewModel()
    @State private var safariURL: URL?

    init(session: LiveSessionStore) {
        self.session = session
        _bookingViewModel = StateObject(wrappedValue: LiveBookingViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let me = session.me {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back,")
                            .font(Font.subheadline)
                            .foregroundStyle(.secondary)
                        Text(me.profile.fullName.isEmpty ? me.profile.email : me.profile.fullName)
                            .font(Font.largeTitle.bold())
                    }
                    .padding(.horizontal)

                    if session.needsWaiver {
                        WaiverBanner(waiverURL: me.waiver.url, safariURL: $safariURL)
                            .padding(.horizontal)
                    }

                    statsRow(me)

                    SectionCard(title: "Next Session") {
                        if let next = bookingViewModel.upcomingBookings.first {
                            LiveBookingRow(booking: next)
                        } else {
                            EmptyStateRow(systemImage: "calendar.badge.plus", message: "No upcoming sessions booked yet.")
                        }
                    }
                    .padding(.horizontal)

                    healthSection
                } else if session.isLoadingMe {
                    ProgressView().padding(.top, 60)
                } else if let error = session.loadError {
                    EmptyStateRow(systemImage: "wifi.exclamationmark", message: error)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Home")
        .task {
            await session.refreshMe()
            await bookingViewModel.load()
            await SessionNotificationScheduler.shared.requestAuthorizationIfNeeded()
            if healthViewModel.isAuthorized {
                await healthViewModel.refresh()
            }
        }
        .refreshable {
            await session.refreshMe()
            await bookingViewModel.load()
            await healthViewModel.refresh()
        }
        .safariSheet($safariURL) {
            Task { await session.refreshMe() }
        }
    }

    @ViewBuilder
    private var healthSection: some View {
        SectionCard(title: "Health & Activity") {
            VStack(alignment: .leading, spacing: 16) {
                if !healthViewModel.isHealthDataAvailable {
                    EmptyStateRow(systemImage: "xmark.circle", message: "Health data isn't available on this device.")
                } else if !healthViewModel.isAuthorized {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Connect Apple Health to see your activity here and track workouts from the app.")
                            .font(Font.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            Task { await healthViewModel.connect() }
                        } label: {
                            Label("Connect Apple Health", systemImage: "applewatch")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.brandPrimary)
                    }
                } else {
                    HealthSummaryRow(summary: healthViewModel.summary)

                    if let last = healthViewModel.recentWorkouts.first {
                        Divider()
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Last workout")
                                .font(Font.caption)
                                .foregroundStyle(.secondary)
                            Text("\(last.activityName) · \(last.durationMinutes) min · \(last.start.formatted(date: .abbreviated, time: .omitted))")
                                .font(Font.subheadline.weight(.medium))
                        }
                    }

                    NavigationLink {
                        LiveWorkoutTrackerView()
                    } label: {
                        Label("Track a Workout", systemImage: "figure.run")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.brandPrimary)
                }
            }
        }
        .padding(.horizontal)
    }

    private func statsRow(_ me: MeResponse) -> some View {
        HStack(spacing: 12) {
            StatTile(
                title: "Credits left",
                value: me.credits.map { "\($0.remaining)" } ?? "—",
                systemImage: "ticket.fill"
            )
            StatTile(
                title: "Plan",
                value: me.plan?.name ?? "None",
                systemImage: "tag.fill"
            )
        }
        .padding(.horizontal)
    }
}

struct LiveBookingRow: View {
    let booking: RemoteBooking

    var body: some View {
        HStack(spacing: 14) {
            VStack {
                Text(booking.startsAt.formatted(.dateTime.day()))
                    .font(Font.title3.bold())
                Text(booking.startsAt.formatted(.dateTime.month(.abbreviated)))
                    .font(Font.caption2)
                    .textCase(.uppercase)
            }
            .foregroundStyle(Color.brandPrimary)
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(booking.startsAt.formatted(date: .omitted, time: .shortened) + " – " + booking.endsAt.formatted(date: .omitted, time: .shortened))
                    .font(Font.subheadline.weight(.semibold))
                if let notes = booking.notes, !notes.isEmpty {
                    Text(notes)
                        .font(Font.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            LiveStatusBadge(status: booking.status)
        }
        .padding(.vertical, 4)
    }
}

struct LiveStatusBadge: View {
    let status: RemoteBookingStatus

    private var tint: Color {
        switch status {
        case .pending: .orange
        case .confirmed: Color.brandPrimary
        case .completed: .green
        case .cancelled: .red
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(Font.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }
}
