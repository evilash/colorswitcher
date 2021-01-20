//
//  GIFManager.swift
//  ColorSwitcher
//
//  Created by Matt M Smith on 9/28/20.
//

import Combine
import Foundation

struct GIFManager {
    static private let apiKey = Tenor.apiKey
    static private let baseURL = Tenor.baseURL
    static private let filters = Tenor.filters
    
    static func fetchGif(from query: String) -> AnyPublisher<GIFModel, ProjectError> {
        let formattedQuery = query.replacingOccurrences(of: " ", with: "+")
        let urlString = "\(baseURL)?key=\(apiKey)&q=\(formattedQuery)&\(filters)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: ProjectError.gifUrlIsNil)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { response in
                guard let httpUrlResponse = response.response as? HTTPURLResponse,
                      httpUrlResponse.statusCode == 200 else {
                    throw ProjectError.networkError
                }
                return response.data
            }
            .decode(type: TenorResponse.self, decoder: JSONDecoder())
            .tryMap { tenor in
                guard let results = tenor.results.first, let media = results.media.first else {
                    throw ProjectError.technicalDifficulties
                }
                return GIFModel(title: results.title, urlString: media.gif.url)
            }
            .mapError { ProjectError.map($0) }
            .eraseToAnyPublisher()
    }
}