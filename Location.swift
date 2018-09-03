import Vapor
import FluentProvider
import HTTP

final class Location: Model {
    let storage = Storage()
    
    // MARK: Properties and database keys
    var name: String
    var lat: Double
    var long: Double	
   
    struct Keys {
        static let name = "name"
        static let lat = "lat"
        static let long = "long"
    }
    
    init(name: String, long: Double, lat: Double) {
        self.name = name
        self.lat = lat
        self.long = long
    }
    // MARK: Fluent Serialization
    /// Initializes the User from the
    /// database row
    init(row: Row) throws {
        name = try row.get(Location.Keys.name)
        lat = try row.get(Location.Keys.lat)
        long = try row.get(Location.Keys.long)
    }
    
    // Serializes the User to the database
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Location.Keys.name, name)
        try row.set(Location.Keys.lat, lat)
        try row.set(Location.Keys.long, long)
        return row
    }
}

// MARK: Fluent Preparation

extension Location: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Location
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Location.Keys.name)
            builder.double(Location.Keys.lat)
            builder.double(Location.Keys.long)
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

// MARK: JSON
extension Location: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(
            name: try json.get(Location.Keys.name),
            lat: try json.get(Location.Keys.lat).
            long: try json.get(Location.Keys.long)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Location.Keys.name, name)
        try json.set(Location.Keys.lat, lat)
        try json.set(Location.Keys.long, long)
        return json
    }
}

// MARK: HTTP

// This allows User models to be returned
// directly in route closures
extension Location: ResponseRepresentable { }

// MARK: Update

// This allows the User model to be updated
// dynamically by the request.
extension Location: Updateable {
    // Updateable keys are called when `post.update(for: req)` is called.
    // Add as many updateable keys as you like here.
    public static var updateableKeys: [UpdateableKey<Location>] {
        return [
            UpdateableKey(Location.Keys.name, String.self) { location, content in
                location.name = content
            }
        ]
    }
}

