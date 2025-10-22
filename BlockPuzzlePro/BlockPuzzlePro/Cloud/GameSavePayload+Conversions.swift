import Foundation

extension GridCellPayload {
    init(from cell: GridCell) {
        switch cell {
        case .empty:
            self = GridCellPayload(state: .empty, color: nil)
        case .occupied(let color):
            self = GridCellPayload(state: .occupied, color: color.rawValue)
        case .locked(let color):
            self = GridCellPayload(state: .locked, color: color.rawValue)
        case .preview(let color):
            self = GridCellPayload(state: .preview, color: color.rawValue)
        }
    }
}

extension GridCell {
    init(from payload: GridCellPayload) {
        switch payload.state {
        case .empty:
            self = .empty
        case .occupied:
            if let colorRaw = payload.color, let color = BlockColor(rawValue: colorRaw) {
                self = .occupied(color: color)
            } else {
                self = .empty
            }
        case .locked:
            if let colorRaw = payload.color, let color = BlockColor(rawValue: colorRaw) {
                self = .locked(color: color)
            } else {
                self = .empty
            }
        case .preview:
            if let colorRaw = payload.color, let color = BlockColor(rawValue: colorRaw) {
                self = .preview(color: color)
            } else {
                self = .empty
            }
        }
    }
}

extension BlockPatternPayload {
    init(from pattern: BlockPattern) {
        self = BlockPatternPayload(
            type: pattern.type.rawValue,
            color: pattern.color.rawValue,
            cells: pattern.cells
        )
    }
}

extension BlockPattern {
    init?(payload: BlockPatternPayload) {
        guard
            let type = BlockType(rawValue: payload.type),
            let color = BlockColor(rawValue: payload.color)
        else {
            return nil
        }
        self.init(type: type, color: color, cells: payload.cells)
    }
}
