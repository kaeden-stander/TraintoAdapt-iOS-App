import SwiftUI

struct BookingRow: View {
    let booking: Booking
    let trainerName: String
    var clientName: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            VStack {
                Text(booking.startDate.formatted(.dateTime.day()))
                    .font(Font.title3.bold())
                Text(booking.startDate.formatted(.dateTime.month(.abbreviated)))
                    .font(Font.caption2)
                    .textCase(.uppercase)
            }
            .foregroundStyle(Color.brandPrimary)
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(booking.sessionType.rawValue).font(Font.subheadline.weight(.semibold))
                Text(clientName.map { "\($0) · \(trainerName)" } ?? trainerName)
                    .font(Font.caption)
                    .foregroundStyle(.secondary)
                Text("\(booking.startDate.formatted(date: .omitted, time: .shortened)) · \(booking.durationMinutes) min · \(booking.location)")
                    .font(Font.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
            StatusBadge(status: booking.status)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: BookingStatus

    private var tint: Color {
        switch status {
        case .upcoming: Color.brandPrimary
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
