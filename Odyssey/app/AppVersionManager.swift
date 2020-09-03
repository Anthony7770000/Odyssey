//
//  AppVersionManager.swift
//  Odyssey
//
//  Created by 23 Aaron on 16/08/2020.
//  Copyright © 2020 coolstar. All rights reserved.
//

import Foundation

private struct LatestVersionStruct: Decodable {
    let versionNumber: String
    let latestBlog: URL
    let downloadLink: URL
}

enum AVMError: Error {
    case noData
    case inaccessabileCurrentVerison
}

private let latestReleaseURL = URL(string: "https://theodyssey.dev/api/latest-release.json")!

final class AppVersionManager {
    static let shared = AppVersionManager()
    private var cachedLatestVersion: LatestVersionStruct?
    
    private init() {}
    
    func doesApplicationRequireUpdate(completionHandler: @escaping ((Result<Bool, Error>) -> Void)) {
        let session = URLSession(configuration: .default)
        session.dataTask(with: latestReleaseURL) { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
                return
            }
            
            guard let data = data else {
                completionHandler(.failure(AVMError.noData))
                return
            }
            do {
                let currentRelease = try JSONDecoder().decode(LatestVersionStruct.self, from: data)
            
                self.cachedLatestVersion = currentRelease
            
                let currentVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
                completionHandler(
                    .success(currentVersion.compare(currentRelease.versionNumber) == .orderedAscending)
                )
            } catch {
                completionHandler(.failure(error))
            }
        }.resume()
    }
    
    func launchBestUpdateApplication() {
        guard let downloadLinkURL = cachedLatestVersion?.downloadLink,
              let percentEncodedString = downloadLinkURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        
        let altstoreURL = URL(string: "altstore://install?url=\(percentEncodedString)")!
        UIApplication.shared.open(altstoreURL, options: [:]) { success in
            if !success {
                guard let latestBlogURL = self.cachedLatestVersion?.latestBlog else{
                    return
                }
                UIApplication.shared.open(latestBlogURL, options: [:])
            }
        }
    }
}
