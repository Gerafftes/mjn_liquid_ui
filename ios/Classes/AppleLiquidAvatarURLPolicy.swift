import Foundation

enum AppleLiquidAvatarURLPolicy {
  static func allowedHosts(_ value: Any?) -> Set<String> {
    guard let values = value as? [Any] else {
      return []
    }

    return Set(
      values.compactMap { value in
        guard let host = value as? String else {
          return nil
        }
        return normalizedHost(host)
      }
    )
  }

  static func optionalURL(
    _ value: Any?,
    allowedHosts: Set<String>
  ) -> URL? {
    guard let string = value as? String,
      !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      let url = URL(string: string),
      allows(url, allowedHosts: allowedHosts)
    else {
      return nil
    }

    return url
  }

  static func allows(_ url: URL, allowedHosts: Set<String>) -> Bool {
    guard url.scheme?.lowercased() == "https",
      url.user == nil,
      url.password == nil,
      url.port == nil || url.port == 443,
      let host = url.host.flatMap(normalizedHost),
      allowedHosts.contains(host)
    else {
      return false
    }

    return true
  }

  private static func normalizedHost(_ value: String) -> String? {
    let host = value.trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
    guard !host.isEmpty,
      host.range(
        of: "^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)*$",
        options: .regularExpression
      ) != nil
    else {
      return nil
    }

    let labels = host.split(separator: ".")
    if labels.count == 4 && labels.allSatisfy({ Int($0) != nil }) {
      return nil
    }

    return host
  }
}
