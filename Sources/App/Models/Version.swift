import Fluent
import Vapor


typealias CommitHash = String


final class Version: Model, Content {
    static let schema = "versions"

    typealias Id = UUID

    // managed fields

    @ID(key: .id)
    var id: Id?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    // reference fields

    @Parent(key: "package_id")
    var package: Package

    // data fields

    @Field(key: "commit")
    var commit: CommitHash?

    @Field(key: "commit_date")
    var commitDate: Date?

    @Field(key: "package_name")
    var packageName: String?

    @Field(key: "reference")
    var reference: Reference?

    @Field(key: "supported_platforms")
    var supportedPlatforms: [Platform]

    @Field(key: "swift_versions")
    var swiftVersions: [SwiftVersion]

    // relationships
    
    @Children(for: \.$version)
    var products: [Product]

    init() { }

    init(id: Id? = nil,
         package: Package,
         reference: Reference? = nil,
         packageName: String? = nil,
         commit: CommitHash? = nil,
         commitDate: Date? = nil,
         supportedPlatforms: [Platform] = [],
         swiftVersions: [SwiftVersion] = []) throws {
        self.id = id
        self.$package.id = try package.requireID()
        self.reference = reference
        self.packageName = packageName
        self.commit = commit
        self.commitDate = commitDate
        self.supportedPlatforms = supportedPlatforms
        self.swiftVersions = swiftVersions
    }
}


extension Version: Equatable {
    static func == (lhs: Version, rhs: Version) -> Bool {
        lhs.id == rhs.id
    }
}


extension Version {
    func supportsMajorSwiftVersion(_ swiftVersion: Int) -> Bool {
        Self.supportsMajorSwiftVersion(swiftVersion, values: swiftVersions)
    }

    static func supportsMajorSwiftVersion(_ swiftVersion: Int, value: SwiftVersion) -> Bool {
        return value.major >= swiftVersion
    }

    static func supportsMajorSwiftVersion(_ swiftVersion: Int, values: [SwiftVersion]) -> Bool {
        values.first { supportsMajorSwiftVersion(swiftVersion, value: $0) } != nil
    }
}
