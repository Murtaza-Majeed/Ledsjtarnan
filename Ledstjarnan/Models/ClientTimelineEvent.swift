//
//  ClientTimelineEvent.swift
//  Ledstjarnan
//
//  Matches client_timeline_events table.
//

import Foundation

struct ClientTimelineEvent: Identifiable, Codable {
    let id: String
    let clientId: String
    let unitId: String
    let eventType: String
    let title: String
    let description: String?
    var metadata: [String: AnyCodable]?
    let createdByStaffId: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case clientId = "client_id"
        case unitId = "unit_id"
        case eventType = "event_type"
        case title
        case description
        case metadata
        case createdByStaffId = "created_by_staff_id"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        clientId = try c.decode(String.self, forKey: .clientId)
        unitId = try c.decode(String.self, forKey: .unitId)
        eventType = try c.decode(String.self, forKey: .eventType)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        createdByStaffId = try c.decodeIfPresent(String.self, forKey: .createdByStaffId)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        metadata = try? c.decodeIfPresent([String: AnyCodable].self, forKey: .metadata) ?? nil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(clientId, forKey: .clientId)
        try c.encode(unitId, forKey: .unitId)
        try c.encode(eventType, forKey: .eventType)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(createdByStaffId, forKey: .createdByStaffId)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(metadata, forKey: .metadata)
    }
}

// For JSONB metadata that can hold arbitrary JSON
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) { value = v }
        else if let v = try? container.decode(Int.self) { value = v }
        else if let v = try? container.decode(Double.self) { value = v }
        else if let v = try? container.decode(String.self) { value = v }
        else if let v = try? container.decode([AnyCodable].self) { value = v.map(\.value) }
        else if let v = try? container.decode([String: AnyCodable].self) { value = v.mapValues(\.value) }
        else { value = NSNull() }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Bool: try container.encode(v)
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as [Any]:
            try container.encode(v.map(AnyCodable.init))
        case let v as [String]:
            try container.encode(v.map(AnyCodable.init))
        case let v as [Int]:
            try container.encode(v.map(AnyCodable.init))
        case let v as [Double]:
            try container.encode(v.map(AnyCodable.init))
        case let v as [Bool]:
            try container.encode(v.map(AnyCodable.init))
        case let v as [AnyCodable]:
            try container.encode(v)
        case let v as [String: Any]:
            try container.encode(v.mapValues(AnyCodable.init))
        case let v as [String: AnyCodable]:
            try container.encode(v)
        case let v as [String: String]:
            try container.encode(v.mapValues(AnyCodable.init))
        case let v as [String: Int]:
            try container.encode(v.mapValues(AnyCodable.init))
        case let v as [String: Double]:
            try container.encode(v.mapValues(AnyCodable.init))
        case let v as [String: Bool]:
            try container.encode(v.mapValues(AnyCodable.init))
        case is NSNull:
            try container.encodeNil()
        default: try container.encodeNil()
        }
    }
}
