import SwiftUI

struct LiveAccountView: View {
    @ObservedObject var session: LiveSessionStore
    @StateObject private var billingViewModel: LiveBillingViewModel
    @State private var showingSignOutConfirm = false

    init(session: LiveSessionStore) {
        self.session = session
        _billingViewModel = StateObject(wrappedValue: LiveBillingViewModel(session: session))
    }

    var body: some View {
        List {
            if let me = session.me {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(me.profile.fullName.isEmpty ? me.profile.email : me.profile.fullName)
                            .font(Font.headline)
                        Text(me.profile.email)
                            .font(Font.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Membership") {
                    LabeledContent("Plan", value: me.plan?.name ?? "None")
                    if let credits = me.credits {
                        LabeledContent("Credits remaining", value: "\(credits.remaining)")
                    }
                    if let subscription = me.subscription {
                        LabeledContent("Status", value: subscription.status.capitalized)
                    }
                    LabeledContent("Waiver signed", value: me.waiver.signed ? "Yes" : "No")
                }
            }

            Section("Billing") {
                Button {
                    Task { await billingViewModel.openBillingPortal() }
                } label: {
                    if billingViewModel.isOpeningPortal {
                        ProgressView()
                    } else {
                        Label("Manage billing & subscription", systemImage: "creditcard")
                    }
                }

                if billingViewModel.invoices.isEmpty {
                    Text("No receipts yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(billingViewModel.invoices) { invoice in
                        if let url = invoice.hostedInvoiceUrl {
                            Link(destination: url) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(invoice.description ?? "Invoice")
                                            .foregroundStyle(.primary)
                                        Text(invoice.created.formatted(date: .abbreviated, time: .omitted))
                                            .font(Font.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(invoice.displayAmount)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            if let errorMessage = billingViewModel.errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            Section {
                Link(destination: AppConfig.portal) {
                    Label("Open client portal in browser", systemImage: "safari")
                }
                Link(destination: URL(string: "mailto:\(AppConfig.supportEmail)?subject=Delete%20my%20account")!) {
                    Label("Delete account", systemImage: "person.crop.circle.badge.xmark")
                }
                .foregroundStyle(.red)
            }

            Section {
                Button(role: .destructive) {
                    showingSignOutConfirm = true
                } label: {
                    Text("Sign Out")
                }
            }
        }
        .navigationTitle("Account")
        .task { await billingViewModel.load() }
        .refreshable { await billingViewModel.load() }
        .safariSheet($billingViewModel.portalURL)
        .confirmationDialog("Sign out of TrainToAdapt?", isPresented: $showingSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task { await session.signOut() }
            }
        }
    }
}
