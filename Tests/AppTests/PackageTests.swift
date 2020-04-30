@testable import App

import Fluent
import Vapor
import XCTVapor


final class PackageTests: XCTestCase {
    var app: Application!

    override func setUpWithError() throws {
        app = try setup(.testing)
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    func test_localCacheDirectory() throws {
        XCTAssertEqual(
            Package(url: "https://github.com/finestructure/Arena".url).localCacheDirectory,
            "github.com-finestructure-arena")
        XCTAssertEqual(
            Package(url: "https://github.com/finestructure/Arena.git".url).localCacheDirectory,
            "github.com-finestructure-arena")
        XCTAssertEqual(
            Package(url: "http://github.com/finestructure/Arena.git".url).localCacheDirectory,
            "github.com-finestructure-arena")
        XCTAssertEqual(
            Package(url: "http://github.com/FINESTRUCTURE/ARENA.GIT".url).localCacheDirectory,
            "github.com-finestructure-arena")
        XCTAssertEqual(Package(url: "foo".url).localCacheDirectory, nil)
        XCTAssertEqual(Package(url: "http://foo".url).localCacheDirectory, nil)
        XCTAssertEqual(Package(url: "file://foo".url).localCacheDirectory, nil)
        XCTAssertEqual(Package(url: "http:///foo/bar".url).localCacheDirectory, nil)
    }

    func test_save_status() throws {
        do {  // default status
            try Package(url: "1".url).save(on: app.db).wait()
            let pkg = try XCTUnwrap(try Package.query(on: app.db).first().wait())
            XCTAssertEqual(pkg.status, .none)
        }
        do {  // with status
            try Package(url: "2".url, status: .ok).save(on: app.db).wait()
            let pkg = try XCTUnwrap(try Package.query(on: app.db).filter(by: "2".url).first().wait())
            XCTAssertEqual(pkg.status, .ok)
        }
    }

    func test_encode() throws {
        let p = Package(id: UUID(), url: URL(string: "https://github.com/finestructure/Arena")!)
        p.lastCommitAt = Date()
        let data = try JSONEncoder().encode(p)
        XCTAssertTrue(!data.isEmpty)
    }

    func test_decode() throws {
        let timestamp: TimeInterval = 609426189  // Apr 24, 2020, just before 13:00 UTC
                                                 // Date.timeIntervalSinceReferenceDate
        let json = """
        {
            "id": "CAFECAFE-CAFE-CAFE-CAFE-CAFECAFECAFE",
            "url": "https://github.com/finestructure/Arena",
            "status": "ok",
            "lastCommitAt": \(timestamp)
        }
        """
        let p = try JSONDecoder().decode(Package.self, from: Data(json.utf8))
        XCTAssertEqual(p.id?.uuidString, "CAFECAFE-CAFE-CAFE-CAFE-CAFECAFECAFE")
        XCTAssertEqual(p.url, "https://github.com/finestructure/Arena")
        XCTAssertEqual(p.status, .ok)
        XCTAssertEqual(p.lastCommitAt?.description, "2020-04-24 13:03:09 +0000")
    }

    func test_unique_url() throws {
        try Package(url: "p1".url).save(on: app.db).wait()
        XCTAssertThrowsError(try Package(url: "p1".url).save(on: app.db).wait())
    }

    func test_filter_by_url() throws {
        try ["https://foo.com/1", "https://foo.com/2"].forEach {
            try Package(url: $0.url).save(on: app.db).wait()
        }
        let res = try Package.query(on: app.db).filter(by: "https://foo.com/1".url).all().wait()
        XCTAssertEqual(res.map(\.url), ["https://foo.com/1"])
    }

    func test_updateCandidates() throws {
        let packages = try ["https://foo.com/1", "https://foo.com/2"].map {
            try savePackage(on: app.db, $0.url)
        }
        try Package.update(packages[0])(on: app.db).wait()
        let batch = try Package.query(on: app.db).updateCandidates(limit: 10).wait()
            .map(\.url)
        XCTAssertEqual(batch, ["https://foo.com/2", "https://foo.com/1"])
    }
}