import SwiftUI

struct DataBrowserView: View {
    let viewModel: PrivacyViewModel
    @State private var moments: [Moment] = []
    @State private var searchText = ""

    var filteredMoments: [Moment] {
        if searchText.isEmpty {
            return moments
        }
        return moments.filter { moment in
            moment.emotionTags.contains { $0.label.localizedCaseInsensitiveContains(searchText) } ||
            moment.note?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        List {
            ForEach(filteredMoments) { moment in
                MomentRow(moment: moment)
                    .listRowBackground(Theme.Colors.cardBackground)
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search moments")
        .navigationTitle("All Data")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            moments = DatabaseService.shared.fetchAllMoments()
        }
    }
}

struct MomentRow: View {
    let moment: Moment

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: moment.type.icon)
                .foregroundColor(Theme.Colors.mutedRose)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(moment.type.displayName)
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.charcoal)

                Text(moment.formattedDate)
                    .font(Theme.Typography.captionFont)
                    .foregroundColor(Theme.Colors.warmGray)

                if !moment.emotionTags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(moment.emotionTags.prefix(2)) { tag in
                            Text(tag.label)
                                .font(Theme.Typography.captionFont)
                                .foregroundColor(tag.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(tag.color.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                }
            }

            Spacer()

            Text(String(format: "%.1f", moment.emotionScore))
                .font(Theme.Typography.monoFont)
                .foregroundColor(Theme.Colors.emotionColor(for: moment.emotionScore))
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

#Preview {
    NavigationStack {
        DataBrowserView(viewModel: PrivacyViewModel())
    }
}
