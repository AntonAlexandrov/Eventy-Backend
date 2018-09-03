//
//  Storage.swift
//  EventyPackageDescription
//
//  Created by Emil Atanasov on 16.02.18.
//

import Vapor
import Multipart
import Foundation

public class FileStorage {
    
    let publicDir:String
    
    init(to drop:Droplet) {
        publicDir = drop.config.workDir + "Public/"
    }

//    func uploadFile(bytes: [UInt8], folder: String) throws -> String {
//        let orgPath = publicDir + folder
//        return try createDirectory(bytes: bytes, originalPath: orgPath)
//    }
//
//    func createDirectory(bytes: [UInt8], originalPath: String) throws -> String {
//        let name = UUID().uuidString
//        //TODO: fix the extension
//        let fileName = "\(name).jpeg"
//        do {
//            try FileManager.default.createDirectory(atPath: originalPath, withIntermediateDirectories: true, attributes: nil)
//            let fullPath = originalPath + "/" + fileName
//            let _ = FileManager.default.createFile(atPath: fullPath, contents: Data(bytes: bytes), attributes: nil)
//
//            return fileName
//        } catch let error as Error {
//            //            switch error.code {
//            //            case 4:
//            //                return save(path: path.0, imageName: path.1,file: file)
//            //            case 516:
//            //                return save(path: path.0, imageName: path.1,file: file)
//            //            default:
//            //                return ""
//            //            }
//            throw Abort.badRequest
//        }
//    }
    
    func uploadFile(part: Part, folder: String) throws -> String {
        let orgPath = publicDir + folder
        return try createDirectory(file: part, originalPath: orgPath)
    }
    
    func createDirectory(file: Part, originalPath: String) throws -> String {
        print(file)
        let path = file.getPath(originalPath)
        print(path)
        do {
            try FileManager.default.createDirectory(atPath: originalPath, withIntermediateDirectories: true, attributes: nil)
            return self.save(path: path.0, fileName: path.1, file: file)
        } catch let error as Error {
            throw Abort.badRequest
        }
    }
    
    //Actual saving
    func save(path: String, fileName: String, file: Part) -> String {
        let _ = FileManager.default.createFile(atPath: path, contents: Data(bytes: file.body), attributes: nil)
        return fileName
    }
}

extension Part {
    func getPath(_ folder: String) -> (String,String) {
        var imagePath = ""
        var imageName = ""
        let name = UUID().uuidString
        //previously the else clause returned ("",""). Currently hardcoded
        //values are used for testing purposes.
        guard let type = self.headers[.contentType] else {return ("\(folder)/\(name).jpeg","test.jpg")}
        switch type {
        case "image/jpeg":
            imagePath = "\(folder)/\(name).jpeg"
            imageName = "\(name).jpeg"
        case "image/jpg":
            imagePath = "\(folder)/\(name).jpg"
            imageName = "\(name).jpg"
        case "image/png":
            imagePath = "\(folder)/\(name).png"
            imageName = "\(name).png"
        default:
            imagePath = "\(folder)/\(name).jpg"
            imageName = "\(name).jpeg"
        }
        return (imagePath,imageName)
    }
}

extension String {
    
    func isImage() -> Bool{
        if self == "image/jpeg" || self == "image/jpg" || self == "image/png" {
            return true
        } else {
            return false
        }
    }
    
}
