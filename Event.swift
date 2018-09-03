import Vapor
import FluentProvider
import HTTP

final class Event: Model {
    let storage = Storage()
    
    // MARK: Properties and database keys
    var creatorId: Identifier?
    var title: String
    var description: String?
    var startDate: Date?
    var endDate: Date?
    var location: Identifier?
	
   
    struct Keys {
        static let creatorId = "creatorId"
        static let title = "title"
        static let description = "description"
        static let startDate = "startDate"
        static let endDate = "endDate"
		static let locationId = "locationId"
    }
    
    init(title: String, description: String?, startDate:Date?, endDate:Date?) {
        self.title = title
        self.description = description
    }
    // MARK: Fluent Serialization
    /// Initializes the User from the
    /// database row
    init(row: Row) throws {
        username = try row.get(User.Keys.username)
        password = try row.get(Event.Keys.password)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Event.Keys.username, username)
        try row.set(Event.Keys.password, password)
        return row
    }
}

// MARK: Fluent Preparation

extension Event: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(Event.Keys.username)
            builder.string(Event.Keys.password)
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

// MARK: JSON
extension Event: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(
            username: try json.get(User.Keys.username),
            password: try json.get(User.Keys.password)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(User.Keys.username, username)
        try json.set(User.Keys.password, password)
        return json
    }
}

// MARK: HTTP

// This allows User models to be returned
// directly in route closures
extension User: ResponseRepresentable { }

// MARK: Update

// This allows the User model to be updated
// dynamically by the request.
extension User: Updateable {
    // Updateable keys are called when `post.update(for: req)` is called.
    // Add as many updateable keys as you like here.
    public static var updateableKeys: [UpdateableKey<User>] {
        return [
            // If the request contains a String at key "content"
            // the setter callback will be called.
            UpdateableKey(User.Keys.password, String.self) { user, content in
                user.password = content
            }
        ]
    }
}

