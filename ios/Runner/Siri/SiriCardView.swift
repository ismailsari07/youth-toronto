import SwiftUI

// The snippet under Siri's answer, in the widget's palette (night navy, white
// text, the app's green), navy in light and dark mode alike. No buttons.

private enum SiriPalette {
  static let night = Color(red: 14 / 255, green: 26 / 255, blue: 43 / 255)
  static let green = Color(red: 14 / 255, green: 117 / 255, blue: 80 / 255)
  static let mint = Color(red: 92 / 255, green: 203 / 255, blue: 148 / 255)
  static let label = Color.white.opacity(0.8)
  static let secondary = Color.white.opacity(0.78)
}

@available(iOS 16.0, *)
struct SiriCardView: View {
  let card: SiriCard

  var body: some View {
    content
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
      .background(SiriPalette.night)
  }

  @ViewBuilder
  private var content: some View {
    switch card {
    case let .message(text):
      HStack(alignment: .top, spacing: 10) {
        Image(systemName: "moon.stars.fill")
          .foregroundColor(SiriPalette.mint)
        Text(text)
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(.white)
      }

    case let .prayer(eyebrow, name, big, lines):
      VStack(alignment: .leading, spacing: 4) {
        eyebrowText(eyebrow)
        Text(name)
          .font(.system(size: 22, weight: .bold))
          .foregroundColor(.white)
        if let big = big {
          Text(big)
            .font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
            .foregroundColor(SiriPalette.mint)
        }
        ForEach(lines, id: \.self) { line in
          Text(line)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(SiriPalette.secondary)
        }
      }

    case let .table(title, rows, footer):
      VStack(alignment: .leading, spacing: 2) {
        eyebrowText(title)
          .padding(.bottom, 6)
        ForEach(rows, id: \.name) { row in
          tableRow(row)
        }
        if let footer = footer {
          Text(footer)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(SiriPalette.mint)
            .padding(.top, 6)
        }
      }

    case let .window(name, status, detail, progress):
      VStack(alignment: .leading, spacing: 4) {
        Text(name)
          .font(.system(size: 22, weight: .bold))
          .foregroundColor(.white)
        Text(status)
          .font(.system(size: 17, weight: .semibold, design: .rounded))
          .foregroundColor(SiriPalette.mint)
        if let detail = detail {
          Text(detail)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(SiriPalette.secondary)
        }
        if let progress = progress {
          ProgressView(value: progress)
            .progressViewStyle(.linear)
            .tint(SiriPalette.mint)
            .padding(.top, 6)
        }
      }

    case let .events(title, items):
      VStack(alignment: .leading, spacing: 10) {
        eyebrowText(title)
        ForEach(items, id: \.self) { item in
          VStack(alignment: .leading, spacing: 2) {
            Text(item.title)
              .font(.system(size: 15, weight: .semibold))
              .foregroundColor(.white)
              .lineLimit(2)
            Text(item.line)
              .font(.system(size: 13, weight: .medium))
              .foregroundColor(SiriPalette.secondary)
            if let next = item.next {
              Text(next)
                .font(.system(size: 12))
                .foregroundColor(SiriPalette.label)
            }
          }
        }
      }

    case let .contact(title, detail):
      VStack(alignment: .leading, spacing: 4) {
        eyebrowText(title)
        Text(detail)
          .font(.system(size: 17, weight: .semibold))
          .foregroundColor(.white)
      }
    }
  }

  private func eyebrowText(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 11, weight: .semibold))
      .kerning(0.6)
      .foregroundColor(SiriPalette.label)
  }

  private func tableRow(_ row: SiriCard.Row) -> some View {
    HStack(spacing: 8) {
      Text(row.name)
        .font(.system(size: 14, weight: row.highlighted ? .bold : .medium))
        .lineLimit(1)
      Spacer(minLength: 8)
      Text(row.time)
        .font(.system(size: 14, weight: row.highlighted ? .bold : .regular).monospacedDigit())
      Text(row.iqamah ?? "")
        .font(.system(size: 12).monospacedDigit())
        .foregroundColor(SiriPalette.mint)
        .frame(width: 66, alignment: .trailing)
    }
    .foregroundColor(row.highlighted ? .white : SiriPalette.secondary)
    .padding(.horizontal, 8)
    .padding(.vertical, 3)
    .background(
      RoundedRectangle(cornerRadius: 6, style: .continuous)
        .fill(row.highlighted ? SiriPalette.green : Color.clear)
    )
  }
}
