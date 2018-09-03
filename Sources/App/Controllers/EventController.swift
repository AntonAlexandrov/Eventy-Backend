import Vapor
import FluentProvider
import AuthProvider
import Multipart
import Foundation //for DateFormatter

struct EventController {
    let fileStorage:FileStorage

    init(storage:FileStorage) {
        self.fileStorage = storage
    }
    
    func addRoutes(to drop: Droplet, middleware: [MiddlewareType: Middleware]) {
        let eventsGroup = drop.grouped("events")
        
        eventsGroup.get("public", handler: allPublicEvents)
        eventsGroup.get("closeby", handler: closebyEvents)
        
        //events/:id/upload - POST - upload asset == DONE
        //events/register - GET (html page) - use private api now
        //events/:id/join - POST (userId) <!--maybe you mean eventId? -->
        //events/members/{id} - GET
        
        //private API will be removed later
        //events/private/create - POST <!--made it events/create-->
        
        let sessionRoute = eventsGroup.grouped([middleware[.session]!])
        
        /**
         * Returns all participants of an event.
         *
         * TODO: Maybe add a check  if the event is public, or that the current
         *       logged in user is participating.
         */
        sessionRoute.get(":id", "members") { request in
            guard let eventId = request.parameters["id"]?.int else {
                throw Abort.badRequest
            }
            
            guard
                let event = try Event.makeQuery().filter("id", eventId).first()
                else {
                    throw Abort.badRequest
            }
            
            return try event.participants.all().makeJSON()
        }

        /** Returns all event assets if the current user is a participant. */
        sessionRoute.grouped([middleware[.persist]!]).get(":id", "assets") {
            request in
            
            let user: User = try request.auth.assertAuthenticated()

            guard let eventId = request.parameters["id"]?.int
            else {
                throw Abort.badRequest
            }

            guard let event = try Event.find(eventId) else {
                throw Abort.notFound
            }
            
            guard try event.participants.isAttached(user) else {
                throw Abort.badRequest
            }

            return try event.assets.all().makeJSON()
        }

        /**
         * Uploads a file to an event.
         *
         * In order for the upload to succeed, a valid event ID must be supplied,
         * a user should be logged in and attending the event.
         *
         * The request must contain form data with key "file" (with quotes) and value
         * an image file. The header must contain Content-Type with value
         * multipart/form-data.
         *
         * NOTE: The file gets corrupted during the saving process. So far it is known
         *       that the first couple of bytes are not saved.
         */
        sessionRoute.grouped([middleware[.persist]!]).post(":id", "upload") {
            request in

            guard let eventId = request.parameters["id"]?.int else {
                throw Abort.badRequest
            }
            
            guard let event = try Event.find(eventId) else {
                throw Abort.notFound
            }

            let user: User = try request.auth.assertAuthenticated()

            guard try event.participants.isAttached(user) else {
                throw Abort.badRequest
            }
            
            guard let file = request.formData?["file"]?.part else {
                throw Abort.badRequest
            }
            
            let relativePath = "assets/\(eventId)"
            
            //it fails to save the file here!
            let fileName = try self.fileStorage.uploadFile(part:file, folder:relativePath)
            let url = relativePath + "/" + fileName
            
            let asset = Asset(name: fileName, url: url)
            try asset.save()
            
            try event.assets.add(asset)
            
            return asset
        }

        /**
         * Joins the current user to an event.
         *
         * If a user is logged in and a valid event ID is supplied through the
         * request, attempts to add the current user as a participant to the event,
         * if he/she is not already participating.
         */
        sessionRoute.grouped([middleware[.persist]!]).post(":id", "join") {
            request in
            
            let user: User = try request.auth.assertAuthenticated()

            guard let eventId = request.parameters["id"]?.int
            else {
                throw Abort.badRequest
            }

            guard let event = try Event.find(eventId) else {
                throw Abort.notFound
            }
            
            if try event.participants.isAttached(user) {
                throw Abort.badRequest
            }

            try event.participants.add(user)

            return event
        }
        
        /**
         * Creates an event.
         * 
         * Parses the event data from the request, creates an event and sets the user
         * creating it as a participant.
         */
        sessionRoute.grouped([middleware[.persist]!]).post("create") { request in

                guard let json = request.json else {
                    throw Abort.badRequest
                }
                
                guard
                    let user = try? request.auth.assertAuthenticated(User.self),
                    let title = json["title"]?.string,
                    let description = json["description"]?.string,
                    let startDateString = json["startDate"]?.string,
                    let endDateString = json["endDate"]?.string,
                    let locationId = json["location"]?.string,
                    let isPrivate = json["isPrivate"]?.bool
                    else {
                        throw Abort.badRequest
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy"

                let startDate = dateFormatter.date(from: startDateString)!
                let endDate = dateFormatter.date(from: endDateString)!
                
                let loc = Location.init(name: "Sofia", lat: 42.0, long: 21.0)
                //TODO: load the location by id?
                try loc.save()
                
                let event = try Event(creator: user, title: title, description: description, startDate: startDate, endDate: endDate, location: loc, isPrivate: isPrivate)

                try event.save()
                try event.participants.add(user)
                
                return event
            }
            
        }
    
    /** Returns all public events. */
    func allPublicEvents(_ req: Request) throws -> ResponseRepresentable {
        let events = try Event.all().filter { $0.isPrivate == false }
        return try events.makeJSON()
    }

    /**
     * Currently returns all events.
     * TODO: find a way to create a query to filter the events by location name.
     */
    func closebyEvents(_ req: Request) throws -> ResponseRepresentable {
        // let events = try Event.query(on: req).join(\Event.location, to: \Location.id)
        //     .filter(Location.name == "Sofia").all()
        
        // return try events.makeJSON()

        let events = try Event.all()

        return try events.makeJSON()
    }
}
