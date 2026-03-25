import SwiftUI

struct DayDetailView: View {
    let date: Date
    let moments: [Moment]
    let onDelete: (Moment) -> Void

    @Environment(\.dismiss) private var dismiss

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    if moments.isEmpty {
                        EmptyDayView()
                    } else {
                        ForEach(moments) { moment in
                            MomentCard(moment: moment, showDate: false)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        onDelete(moment)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .padding(Theme.Spacing.screenMargin)
            }
            .background(Theme.Colors.primaryBackground)
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.mutedRose)
                }
            }
        }
    }
}

struct EmptyDayView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "moon.stars")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.warmGray.opacity(0.5))

            Text("No moments captured")
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.Colors.warmGray)

            Text("Tap the Capture tab to add a moment")
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.Colors.warmGray.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, Theme.Spacing.xxl)
    }
}

#Preview {
    DayDetailView(date: Date(), moments: []) { _ in }
}
