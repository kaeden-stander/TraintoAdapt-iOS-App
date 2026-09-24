import SwiftUI

struct LivePlansView: View {
    @ObservedObject var session: LiveSessionStore
    @StateObject private var viewModel: LivePlansViewModel
    @State private var category: PlanCategory = .monthly
    @State private var payAsYouGoPeople = 1

    init(session: LiveSessionStore) {
        self.session = session
        _viewModel = StateObject(wrappedValue: LivePlansViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Category", selection: $category) {
                    ForEach(PlanCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView().padding(.top, 40)
                } else if category == .payAsYouGo {
                    payAsYouGoContent
                } else {
                    let plansInCategory = viewModel.plans(in: category)
                    if plansInCategory.isEmpty {
                        EmptyStateRow(systemImage: "tag", message: "No plans available right now.")
                            .padding(.horizontal)
                    } else {
                        ForEach(plansInCategory) { plan in
                            PlanCard(plan: plan, price: plan.priceGbp, detail: detailCaption(for: plan)) {
                                Task { await viewModel.startCheckout(planSlug: plan.slug) }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Plans & Pricing")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .safariSheet($viewModel.checkoutURL) {
            Task { await session.refreshMe() }
        }
    }

    private var payAsYouGoContent: some View {
        VStack(spacing: 20) {
            Picker("People", selection: $payAsYouGoPeople) {
                Text("1 person").tag(1)
                Text("2 people").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if let plan = viewModel.plans(in: .payAsYouGo).first {
                let price = payAsYouGoPeople == 2
                    ? (viewModel.topup?.twoPersonPriceGbp ?? plan.priceGbp)
                    : (viewModel.topup?.priceGbp ?? plan.priceGbp)
                let detail = payAsYouGoPeople == 2
                    ? "60 minutes, 2 people (£\(Int((price / 2).rounded())) each)"
                    : "60 minutes, 1 person"

                PlanCard(plan: plan, price: price, detail: detail, buttonTitle: "Book a session") {
                    Task { await viewModel.startCheckout(people: payAsYouGoPeople) }
                }
                .padding(.horizontal)
            } else {
                EmptyStateRow(systemImage: "tag", message: "No pay-as-you-go pricing available right now.")
                    .padding(.horizontal)
            }
        }
    }

    private func detailCaption(for plan: PlanDetails) -> String? {
        switch category {
        case .monthly:
            guard let count = plan.monthlySessionCount, let weekly = plan.weeklySessions else { return nil }
            return "\(count) sessions a month (\(weekly) a week)"
        case .online:
            guard let weekly = plan.weeklySessions else { return nil }
            return "\(weekly) workouts a week"
        case .home, .payAsYouGo:
            return nil
        }
    }
}

private struct PlanCard: View {
    let plan: PlanDetails
    let price: Double
    let detail: String?
    var buttonTitle: String? = nil
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if plan.isPopular == true {
                Text("Most popular")
                    .font(Font.caption2.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.brandPrimary.opacity(0.15), in: Capsule())
                    .foregroundStyle(Color.brandPrimary)
            }

            Text(plan.name)
                .font(Font.title2.bold())
                .foregroundStyle(Color.brandPrimary)

            if let tagline = plan.tagline {
                Text(tagline)
                    .font(Font.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("£\(Int(price.rounded()))")
                    .font(Font.largeTitle.bold())
                Text(unitLabel)
                    .font(Font.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let detail {
                Text(detail)
                    .font(Font.subheadline)
                    .foregroundStyle(Color.brandPrimary)
            }

            if let features = plan.features, !features.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(features, id: \.self) { feature in
                        Label(feature, systemImage: "checkmark")
                            .font(Font.subheadline)
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(.primary)
                    }
                }
            }

            Button(action: onSelect) {
                Text(buttonTitle ?? "Start \(plan.name) plan")
                    .fontWeight(.semibold)
                    .foregroundStyle(plan.isPopular == true ? .black : Color.brandPrimary)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(plan.isPopular == true ? .borderedProminent : .bordered)
            .tint(Color.brandPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brandPrimary, lineWidth: plan.isPopular == true ? 2 : 0)
        )
    }

    private var unitLabel: String {
        switch plan.billingInterval {
        case "month": "/month"
        case "session": "/session"
        default: ""
        }
    }
}
