import Vapor
import FluentProvider
import HTTP
import AuthProvider

final class User: Model {
    let storage = Storage()
    
    // MARK: Properties and database keys
    var username: String
    var password: String
    
    
    /// The column names for `id` and `content` in the database
    struct Keys {
        static let username = "username"
        static let password = "password"
    }
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    // MARK: Fluent Serialization
    /// Initializes the User from the
    /// database row
    init(row: Row) throws {
        username = try row.get(User.Keys.username)
        password = try row.get(User.Keys.password)
    }
    
    // Serializes the User to the database
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(User.Keys.username, username)
        try row.set(User.Keys.password, password)
        return row
    }
}

// MARK: Fluent Preparation

extension User: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Users
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string(User.Keys.username)
            builder.string(User.Keys.password)
        }
    }
    
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

// MARK: JSON
extension User: JSONConvertible {
    convenience init(json: JSON) throws {
        self.init(
            username: try json.get(User.Keys.username),
            password: try json.get(User.Keys.password)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(User.Keys.username, username)
        //It is a security risk if the password is also returned.
        // try json.set(User.Keys.password, password)
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


//MARK : Authentication
extension User: PasswordAuthenticatable {
    public var hashedPassword: String? {
        return password
    }
    public static var passwordVerifier: PasswordVerifier? {
        return SimplePasswordVerifier()
    }
    
    public static var usernameKey: String {
        return "username"
    }
}

extension User: SessionPersistable {}

struct SimplePasswordVerifier: PasswordVerifier {
    func verify(password: Bytes, matches hash: Bytes) throws -> Bool {
        return try BCryptHasher().verify(password: password, matches: hash)
    }
}

/** Allows access to all events which the user is attending. */
extension User {
    var events: Siblings<User, Event, Pivot<User, Event>> {
        return siblings()
    }
}
