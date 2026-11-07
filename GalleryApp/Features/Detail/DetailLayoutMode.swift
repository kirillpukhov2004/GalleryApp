import CoreGraphics

enum DetailLayoutMode: Equatable {
    case portrait
    case landscape

    static func mode(for size: CGSize) -> DetailLayoutMode {
        size.width > size.height ? .landscape : .portrait
    }
}
