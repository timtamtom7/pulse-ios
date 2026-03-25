import SwiftUI

struct EmotionTagView: View {
    let tag: EmotionTag

    var body: some View {
        Text(tag.label)
            .font(Theme.Typography.emotionTagFont)
            .foregroundColor(tag.color)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(tag.color.opacity(0.15))
            .cornerRadius(Theme.CornerRadius.small)
    }
}

#Preview {
    HStack {
        EmotionTagView(tag: EmotionTag(category: .joy, confidence: 0.9, label: "Happy"))
        EmotionTagView(tag: EmotionTag(category: .sadness, confidence: 0.7, label: "Sad"))
        EmotionTagView(tag: EmotionTag(category: .neutral, confidence: 0.8, label: "Calm"))
    }
    .padding()
}
