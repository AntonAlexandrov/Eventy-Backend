import Vapor
import FluentProvider
import HTTP

final class Asset: Model {
    let storage = Storage()
    
    fileprivate static let tableName = "Assets"
    
    var id: Node?
    var name: String
    var url: String
    
    struct Keys {
        static let name = "name"
        static let url = "url"
    }

    init(name:String, url:String) {
        self.name = name
        self.url = url
    }
    // MARK: Fluent Serialization
    /// Initializes the Asset from the
    /// database row
    init(row: Row) throws {
        name = try row.get(Asset.Keys.name)
        url = try row.get(Asset.Keys.url)
    }

    // Serializes the User to the database
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Asset.Keys.name, name)
        try row.set(Asset.Keys.url, url)
        return row
    }
    
}

extension Asset: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) {
            $0.id()
            $0.string("name")
            $0.string("url")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

// MARK: JSON
extension Asset: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(
            name: try json.get(Asset.Keys.name),
            url: try json.get(Asset.Keys.url)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Asset.Keys.name, name)
        try json.set(Asset.Keys.url, url)
        return json
    }
}


// MARK: HTTP

// This allows Asset models to be returned
// directly in route closures
extension Asset: ResponseRepresentable { }

// MARK: Update

// This allows the Asset model to be updated
// dynamically by the request.
//extension Asset: Updateable {
//    // Updateable keys are called when `post.update(for: req)` is called.
//    // Add as many updateable keys as you like here.
//    public static var updateableKeys: [UpdateableKey<Asset>] {
//        return [
//            // If the request contains a String at key "content"
//            // the setter callback will be called.
//            UpdateableKey(Asset.Keys.key, String.self) { obj, content in
//                obj.key = content
//            }
//        ]
//    }
//}
