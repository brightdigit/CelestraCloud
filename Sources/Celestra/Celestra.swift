import ArgumentParser
import Foundation
import MistKit

@main
struct Celestra: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "celestra",
        abstract: "RSS reader that syncs to CloudKit public database",
        discussion: """
            Celestra demonstrates MistKit's query filtering and sorting features by managing \
            RSS feeds in CloudKit's public database.
            """,
        subcommands: [
            AddFeedCommand.self,
            UpdateCommand.self,
            ClearCommand.self
        ]
    )
}
