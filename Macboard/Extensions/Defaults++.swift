import Defaults

extension Defaults.Keys {
    static let autoUpdate = Key<Bool>("autoUpdate", default: false)
    static let showSearchbar = Key<Bool>("showSearchbar", default: true)
    static let showUrlMetadata = Key<Bool>("showUrlMetadata", default: true)
    static let maxItems = Key<Int>("maxItems", default: 200)
    static let allowedTypes = Key<[String]>("allowedTypes", default: ["Text", "Image", "File"])
    static let menubarIcon = Key<MenubarIcon>("menubarIcon", default: .normal)
}
