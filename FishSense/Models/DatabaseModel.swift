//
//  DatabaseModel.swift
//  FishSense
//
//  Created by Chris Crutchfield on 5/14/25.
//  Copyright © 2025 E4E. All rights reserved.
//
import ARKit
import Foundation
import SQLite3

class DatabaseModel {
    var database: OpaquePointer?
    var numPhoto = 0
    var currPhoto = 0
    var remoteSet = false
    let apiGatewayURL = "https://YOUR_API_GATEWAY_URL.amazonaws.com/prod/create-table"
    let path = "database.sqlite"
    
    init?() {
        database = createDatabase()
        let _ = createTables()
    }
    
    func createDatabase() -> OpaquePointer? {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let databasePath = documentsDirectory.appendingPathComponent(path)
            
            var databasePointer: OpaquePointer? = nil
            if sqlite3_open(databasePath.path, &databasePointer) == SQLITE_OK {
                return databasePointer
            }
        }
        
        return nil
    }
    
    func createTables() -> Bool {
        if database == nil {
            return false
        }
        
        return createPhotosTable()
    }
    
    func createPhotosTable() -> Bool {
        let query = """
            CREATE TABLE IF NOT EXISTS photos (
                id INTEGER PRIMARY KEY,
                utc_unix_timestamp INTEGER,
                rgb_path TEXT,
                depth_bytes BLOB,
                depth_width INTEGER,
                depth_height INTEGER,
                confidence_bytes BLOB,
                confidence_width INTEGER,
                confidence_height INTGER
            );
            """
        var statement: OpaquePointer? = nil;
        
        if sqlite3_prepare_v2(self.database, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                let errmsg = String(cString: sqlite3_errmsg(database))
                print("Sqlite Error: \(errmsg)")
                
                return false
            }
        } else {
            let errmsg = String(cString: sqlite3_errmsg(database))
            print("Sqlite Error: \(errmsg)")
            
            return false
        }
        
        sqlite3_finalize(statement)
        return true
    }
    
    func insertPhoto(with photo: PhotoModel) -> Bool {
        let query = """
            INSERT INTO photos
            (utc_unix_timestamp, rgb_path, depth_bytes, depth_width, depth_height, confidence_bytes, confidence_width, confidence_height)
            VALUES
            (?, ?, ?, ?, ?, ?, ?, ?)
            """
        var statement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int64(statement, 1, photo.utcUnixTimestamp)
            sqlite3_bind_text(statement, 2, (photo.rgbPath as NSString).utf8String, -1, nil)
            
            sqlite3_bind_blob(statement, 3, photo.depthMap.bytes, Int32(photo.depthMap.width * photo.depthMap.height * MemoryLayout<Float32>.size), nil)
            sqlite3_bind_int(statement, 4, Int32(photo.depthMap.width))
            sqlite3_bind_int(statement, 5, Int32(photo.depthMap.height))
            
            sqlite3_bind_blob(statement, 6, photo.confidenceMap.bytes, Int32(photo.confidenceMap.width * photo.confidenceMap.height * MemoryLayout<ARConfidenceLevel>.size), nil)
            sqlite3_bind_int(statement, 7, Int32(photo.confidenceMap.width))
            sqlite3_bind_int(statement, 8, Int32(photo.confidenceMap.height))
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let errmsg = String(cString: sqlite3_errmsg(database))
                print("Sqlite Error: \(errmsg)")
                
                return false
            }
        }
        else {
            let errmsg = String(cString: sqlite3_errmsg(database))
            print("Sqlite Error: \(errmsg)")
            
            return false
        }
        numPhoto += 1
        
        return true
    }
    
    func createRemoteDatabase(completion: @escaping (Bool, String) -> Void){
        let apiGatewayURL = "https://2h11um1vw5.execute-api.us-west-1.amazonaws.com/default/fishSense"
        let apiKey = "apikey_dipole"
        guard let url = URL(string: apiGatewayURL)
        else {
            completion(false, "Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add authentication headers
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("fishsense-ios-app", forHTTPHeaderField: "x-app-id")

        // Add device identifier
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        request.setValue(deviceId, forHTTPHeaderField: "x-device-id")
        
        // Add timestamp
        let timestamp = String(Int(Date().timeIntervalSince1970))
        request.setValue(timestamp, forHTTPHeaderField: "x-timestamp")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Connection error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(false, "Invalid response")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    if let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let success = json?["success"] as? Bool, success {
                                completion(true, "Table created successfully!")
                            } else {
                                let errorMsg = json?["error"] as? String ?? "Unknown error"
                                completion(false, "Database error: \(errorMsg)")
                            }
                        } catch {
                            completion(false, "Failed to parse response")
                        }
                    }
                } else {
                    completion(false, "Server error: \(httpResponse.statusCode)")
                }
            }
        }
        
        task.resume()
        
        return
    }
}

extension DatabaseModel {
    
    // Get all photos from local database
    func getAllPhotos() -> [[String: Any]]? {
        guard let database = database else { return nil }
        
        let query = """
            SELECT utc_unix_timestamp, rgb_path, depth_bytes, depth_width, depth_height,
                   confidence_bytes, confidence_width, confidence_height
            FROM photos
            ORDER BY utc_unix_timestamp DESC
        """
        
        var statement: OpaquePointer?
        var photos: [[String: Any]] = []
        
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var photo: [String: Any] = [:]
                
                // Get basic fields
                photo["utc_unix_timestamp"] = sqlite3_column_int64(statement, 0)
                
                if let rgbPathCString = sqlite3_column_text(statement, 1) {
                    photo["rgb_path"] = String(cString: rgbPathCString)
                }
                
                photo["depth_width"] = sqlite3_column_int(statement, 3)
                photo["depth_height"] = sqlite3_column_int(statement, 4)
                photo["confidence_width"] = sqlite3_column_int(statement, 6)
                photo["confidence_height"] = sqlite3_column_int(statement, 7)
                
                // Get binary data and convert to base64
                if let depthBytes = sqlite3_column_blob(statement, 2) {
                    let depthSize = sqlite3_column_bytes(statement, 2)
                    let depthData = Data(bytes: depthBytes, count: Int(depthSize))
                    photo["depth_bytes"] = depthData.base64EncodedString()
                }
                
                if let confidenceBytes = sqlite3_column_blob(statement, 5) {
                    let confidenceSize = sqlite3_column_bytes(statement, 5)
                    let confidenceData = Data(bytes: confidenceBytes, count: Int(confidenceSize))
                    photo["confidence_bytes"] = confidenceData.base64EncodedString()
                }
                
                photos.append(photo)
            }
        } else {
            let errmsg = String(cString: sqlite3_errmsg(database))
            print("SQLite Error: \(errmsg)")
            return nil
        }
        
        sqlite3_finalize(statement)
        return photos
    }
    
    // Upload all photos to AWS
    func syncPhotosToAWS(completion: @escaping (Bool, String) -> Void) {
        guard let photos = getAllPhotos() else {
            completion(false, "Failed to read local photos")
            return
        }
        
        if photos.isEmpty {
            completion(true, "No photos to sync")
            return
        }
        
        uploadPhotosToAWS(photos: photos, completion: completion)
    }
    
    private func uploadPhotosToAWS(photos: [[String: Any]], completion: @escaping (Bool, String) -> Void) {
        let uploadURL = "https://t3qqcpry3a.execute-api.us-west-1.amazonaws.com/default/fishsense_add_photo"
        
        guard let url = URL(string: uploadURL) else {
            completion(false, "Invalid upload URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers
        request.setValue("apikey_dipole", forHTTPHeaderField: "x-api-key")
        request.setValue("fishsense-ios-app", forHTTPHeaderField: "x-app-id")
        
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        request.setValue(deviceId, forHTTPHeaderField: "x-device-id")
        
        let timestamp = String(Int(Date().timeIntervalSince1970))
        request.setValue(timestamp, forHTTPHeaderField: "x-timestamp")
        
        // Create request body
        let requestBody = ["photos": photos]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(false, "Failed to serialize photos data")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(false, "Invalid response")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    if let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let success = json?["success"] as? Bool, success {
                                let count = json?["uploaded_count"] as? Int ?? 0
                                completion(true, "Successfully synced \(count) photos")
                            } else {
                                let errorMsg = json?["error"] as? String ?? "Unknown error"
                                completion(false, "Upload error: \(errorMsg)")
                            }
                        } catch {
                            completion(false, "Failed to parse response")
                        }
                    }
                } else {
                    completion(false, "Server error: \(httpResponse.statusCode)")
                }
            }
        }
        
        task.resume()
    }
}
