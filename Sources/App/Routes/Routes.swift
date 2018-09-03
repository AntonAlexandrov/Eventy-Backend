import Vapor
import AuthProvider
import Sessions

extension Droplet {
    func setupRoutes() throws {
        get("hello") { req in
            var json = JSON()
            try json.set("hello", "world")
            return json
        }
        
        get("plaintext") { req in
            return "Hello, world!"
        }
        
        // response to requests to /info domain
        // with a description of the request
        get("info") { req in
            return req.description
        }
        
        get("description") { req in return req.description }
        
        //TODO:
        
        let persistMW = PersistMiddleware(User.self)
        let memory = MemorySessions()
        let sessionMW = SessionsMiddleware(memory)
        let passwordMW = PasswordAuthenticationMiddleware(User.self)
        let storage = FileStorage(to:self)
        
        let userController = UserController(storage:storage)
        userController.addRoutes(to:self, middleware: [.session: sessionMW, .persist: persistMW, .password: passwordMW])
        
        let eventController = EventController(storage:storage)
        eventController.addRoutes(to:self, middleware: [.session: sessionMW, .persist: persistMW])

        //events - GET (key & uid)
        //event/:id - GET - event details
        
        //SECURED:
        //user/profile - POST, GET
        //user/forgot - POST - TBD
        //event/:id/upload - POST - upload asset
        //event/register - GET (html page)
        //event/join - POST (userId)
        //event/:id/members - GET
        
        //TBD
        //asset/:id - GET (comments)
    }
}
