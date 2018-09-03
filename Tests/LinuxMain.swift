#if os(Linux)

import XCTest
@testable import AppTests

XCTMain([
    testCase(EventParticipantsTests.allTests),
    testCase(EventAssetsTests.allTests),
    testCase(AssetTests.allTests),
    testCase(LocationTests.allTests),
    // AppTests
    testCase(PostControllerTests.allTests),
    testCase(RouteTests.allTests)
])

#endif
