import Foundation
import SwiftUI

struct AniListMedia: Identifiable, Decodable {
    let id: Int
    let title: String
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case coverImage
    }
    
    init(id: Int, title: String, imageUrl: String?) {
        self.id = id
        self.title = title
        self.imageUrl = imageUrl
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        let titleContainer = try container.nestedContainer(keyedBy: TitleKeys.self, forKey: .title)
        title = try titleContainer.decodeIfPresent(String.self, forKey: .romaji) ??
                titleContainer.decodeIfPresent(String.self, forKey: .english) ??
                titleContainer.decodeIfPresent(String.self, forKey: .native) ??
                "Unknown"
        if let coverImageContainer = try? container.nestedContainer(keyedBy: CoverImageKeys.self, forKey: .coverImage) {
            imageUrl = try coverImageContainer.decodeIfPresent(String.self, forKey: .large)
        } else {
            imageUrl = nil
        }
    }
    
    enum TitleKeys: String, CodingKey {
        case romaji, english, native
    }
    enum CoverImageKeys: String, CodingKey {
        case large
    }
}

class AniListAPI {
    static func searchAnime(query: String, completion: @escaping ([AniListMedia]) -> Void) {
        search(query: query, type: "ANIME", completion: completion)
    }
    static func searchManga(query: String, completion: @escaping ([AniListMedia]) -> Void) {
        search(query: query, type: "MANGA", completion: completion)
    }
    private static func search(query: String, type: String, completion: @escaping ([AniListMedia]) -> Void) {
        let url = URL(string: "https://graphql.anilist.co")!
        let queryString = """
        query ($search: String!) {
          Page(perPage: 10) {
            media(search: $search, type: \(type)) {
              id
              title { romaji english native }
              coverImage { large }
            }
          }
        }
        """
        let json: [String: Any] = [
            "query": queryString,
            "variables": ["search": query]
        ]
        let body = try! JSONSerialization.data(withJSONObject: json)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { completion([]); return }
            do {
                let decoded = try JSONDecoder().decode(AniListResponse.self, from: data)
                let media = decoded.data.page.media
                DispatchQueue.main.async { completion(media) }
            } catch {
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }
    static func fetchUserAnimeList(accessToken: String, completion: @escaping ([AniListMedia]) -> Void) {
        let url = URL(string: "https://graphql.anilist.co")!
        let query = """
        query { 
            MediaListCollection(userId: null, type: ANIME) {
                lists {
                    entries {
                        media {
                            id
                            title { romaji english native }
                            coverImage { large }
                        }
                    }
                }
            }
        }
        """
        let json: [String: Any] = [
            "query": query
        ]
        let body = try! JSONSerialization.data(withJSONObject: json)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { completion([]); return }
            do {
                let decoded = try JSONDecoder().decode(UserAnimeListResponse.self, from: data)
                let media = decoded.data.mediaListCollection.lists.flatMap { $0.entries.map { $0.media } }
                DispatchQueue.main.async { completion(media) }
            } catch {
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }
}

struct AniListResponse: Decodable {
    let data: AniListPage
    struct AniListPage: Decodable {
        let page: AniListMediaList
        enum CodingKeys: String, CodingKey { case page = "Page" }
    }
    struct AniListMediaList: Decodable {
        let media: [AniListMedia]
    }
}

struct UserAnimeListResponse: Decodable {
    let data: MediaListCollectionData
    struct MediaListCollectionData: Decodable {
        let mediaListCollection: MediaListCollection
    }
    struct MediaListCollection: Decodable {
        let lists: [MediaList]
    }
    struct MediaList: Decodable {
        let entries: [MediaListEntry]
    }
    struct MediaListEntry: Decodable {
        let media: AniListMedia
    }
} 