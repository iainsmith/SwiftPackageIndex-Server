@testable import App

import Vapor
import XCTest


class ReconcilerTests: XCTestCase {
    var app: Application!

    override func setUpWithError() throws {
        app = try setup(.testing)
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    func test_basic_reconciliation() throws {
        let urls = ["1", "2", "3"]
        Current.fetchMasterPackageList = { _ in .just(value: urls.urls) }

        try reconcile(client: app.client, database: app.db).wait()

        let packages = try Package.query(on: app.db).all().wait()
        XCTAssertEqual(packages.map(\.url).sorted(), urls.sorted())
        packages.forEach {
            XCTAssertNotNil($0.id)
            XCTAssertNotNil($0.createdAt)
            XCTAssertNotNil($0.updatedAt)
        }
    }

    func test_adds_and_deletes() throws {
        // save intial set of packages 1, 2, 3
        try savePackages(on: app.db, ["1", "2", "3"].urls)

        // new package list drops 2, 3, adds 4, 5
        let urls = ["1", "4", "5"]
        Current.fetchMasterPackageList = { _ in .just(value: urls.urls) }

        // MUT
        try reconcile(client: app.client, database: app.db).wait()

        // validate
        let packages = try Package.query(on: app.db).all().wait()
        XCTAssertEqual(packages.map(\.url).sorted(), urls.sorted())
    }
}