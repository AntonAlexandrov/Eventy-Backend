import Vapor
import FluentProvider
import AuthProvider

enum MiddlewareType {
    case session, persist, password
}

struct UserController {
    let fileStorage:FileStorage
    
    init(storage:FileStorage) {
        self.fileStorage = storage
    }
    
    func addRoutes(to drop: Droplet, middleware: [MiddlewareType: Middleware]) {
        let userGroup = drop.grouped("user")
        //user/register - POST
        //user/login - POST
        //user/profile - POST, GET
        userGroup.post("register", handler: createUser)
        userGroup.get(User.parameter, handler: getUser)
        
        let sessionRoute = userGroup.grouped([middleware[.session]!, middleware[.persist]!])
        sessionRoute.post("login", handler: login)
        sessionRoute.get("logout", handler: logout)

        let authRoute = sessionRoute.grouped(middleware[.password]!)
        authRoute.get("profile", handler: profile)
        authRoute.post("profile", handler: updateProfile)
    }

    func createUser(_ req: Request) throws -> ResponseRepresentable {
        guard let json = req.json else {
            throw Abort.badRequest
        }
        
        guard
            let email = json["email"]?.string,
            let password = json["password"]?.string
            else {
                throw Abort.badRequest
        }
        
        guard
            try User.makeQuery().filter("username", email).first() == nil
            else {
                throw Abort.badRequest
        }
        
        let hashedPassword = try BCryptHasher().make(password.bytes).makeString()
        
        let user = User(username: email, password: hashedPassword)
        try user.save()
        
        return user
    }

    func allUsers(_ req: Request) throws -> ResponseRepresentable {
        let users = try User.all()
        return try users.makeJSON()
    }

    func getUser(_ req: Request) throws -> ResponseRepresentable {
        let user = try req.parameters.next(User.self)
        return user
    }
    
    func login(_ req: Request) throws -> ResponseRepresentable {
        
        guard let json = req.json else {
            throw Abort.badRequest
        }
        
        guard
            let email = json["email"]?.string,
            let password = json["password"]?.string
            else {
                throw Abort.badRequest
        }
        
        let credentials = Password(username: email, password: password)
        
        // returns matching user (throws error if user doesn't exist)
        let user = try User.authenticate(credentials)
        
        // persists user and creates a session cookie
        req.auth.authenticate(user)
        
        return user
    }
    
    /** Returns the data for the currently logged in user. */
    func profile(_ req: Request) throws -> ResponseRepresentable {
        // returns user from session
        let user: User = try req.auth.assertAuthenticated()
        return user
    }
    
    /** Updates the profile of the current user with the data from the request. */
    func updateProfile(_ req: Request) throws -> ResponseRepresentable {
        // returns user from session
        let user: User = try req.auth.assertAuthenticated()
        
        guard let json = req.json else {
            throw Abort.badRequest
        }
        
        guard
            let email = json["email"]?.string,
            let password = json["password"]?.string
            else {
                throw Abort.badRequest
        }
        
        let hashedPassword = try BCryptHasher().make(password.bytes).makeString()
        
        user.username = email
        user.password = hashedPassword
        try user.save()
        
        return user
    }
    
    /** Logouts the current user. */
    func logout(_ req: Request) throws -> ResponseRepresentable {
        try req.auth.unauthenticate()
        var json = JSON()
        try json.set("success", true)
        return json
    }
}
