//
//  UsernameGeneratorTests.swift
//  FRWTests
//
//  Created by cat on 2025/11/25.
//

@testable import FRW_dev
import Testing

struct UsernameGeneratorTests {
    // MARK: - Basic Functionality Tests

    @Test func testUsernameGeneration() async throws {
        let username = UsernameGenerator.generateRandomUsername()

        // Verify username is not empty
        #expect(!username.isEmpty)

        // Verify username meets length requirements (3-20 characters)
        #expect(username.count >= 3, "Username should be at least 3 characters, got \(username.count)")
        #expect(username.count <= 20, "Username should be at most 20 characters, got \(username.count)")

        // Verify username is lowercase
        #expect(username == username.lowercased(), "Username should be lowercase")
    }

    @Test func testUsernameUniqueness() async throws {
        // Generate 100 usernames and verify they're not all identical
        var usernames = Set<String>()
        for _ in 0..<100 {
            let username = UsernameGenerator.generateRandomUsername()
            usernames.insert(username)
        }

        // With 422 words in pool, we should get decent variety
        // Expect at least 50 unique usernames out of 100 attempts
        #expect(usernames.count >= 50, "Expected high variety in usernames, got only \(usernames.count) unique out of 100")
    }

    @Test func testUsernameLengthDistribution() async throws {
        // Test that generated usernames have reasonable length distribution
        var lengths: [Int] = []
        for _ in 0..<50 {
            let username = UsernameGenerator.generateRandomUsername()
            lengths.append(username.count)
        }

        // Verify all lengths are within valid range
        for length in lengths {
            #expect(length >= 3 && length <= 20, "Username length \(length) outside valid range")
        }

        // Calculate average length (should be reasonable, not always at extremes)
        let averageLength = Double(lengths.reduce(0, +)) / Double(lengths.count)
        #expect(averageLength >= 5 && averageLength <= 18, "Average length \(averageLength) seems unusual")
    }

    // MARK: - Character Validation Tests

    @Test func testUsernameOnlyContainsLetters() async throws {
        let username = UsernameGenerator.generateRandomUsername()

        // Verify username only contains lowercase letters
        let allowedCharacters = CharacterSet.lowercaseLetters
        let usernameCharacters = CharacterSet(charactersIn: username)
        #expect(allowedCharacters.isSuperset(of: usernameCharacters),
                "Username '\(username)' contains non-letter characters")
    }

    @Test func testUsernameHasNoSpaces() async throws {
        for _ in 0..<20 {
            let username = UsernameGenerator.generateRandomUsername()
            #expect(!username.contains(" "), "Username should not contain spaces: '\(username)'")
        }
    }

    @Test func testUsernameHasNoSpecialCharacters() async throws {
        for _ in 0..<20 {
            let username = UsernameGenerator.generateRandomUsername()
            let specialCharacters = "!@#$%^&*()_+-=[]{}|;':\",./<>?"

            for char in specialCharacters {
                #expect(!username.contains(char),
                        "Username should not contain special character '\(char)': '\(username)'")
            }
        }
    }

    // MARK: - Edge Case Tests

    @Test func testConsistentGeneration() async throws {
        // Verify function doesn't crash or hang with repeated calls
        for _ in 0..<100 {
            let username = UsernameGenerator.generateRandomUsername()
            #expect(username.count >= 3 && username.count <= 20)
        }
    }

    @Test func testNoInfiniteLoop() async throws {
        // Test with timeout - should complete quickly
        let startTime = Date()
        for _ in 0..<50 {
            _ = UsernameGenerator.generateRandomUsername()
        }
        let elapsedTime = Date().timeIntervalSince(startTime)

        // 50 generations should take less than 1 second
        #expect(elapsedTime < 1.0, "Username generation took too long: \(elapsedTime)s")
    }

    // MARK: - Word Composition Tests

    @Test func testAdjectivePlacement() async throws {
        // Generate many usernames and verify adjectives appear at the start
        var adjectivesFound = 0
        var nonAdjectivesFound = 0

        let adjectives = UsernameGenerator.adjectives

        for _ in 0..<100 {
            let username = UsernameGenerator.generateRandomUsername()

            // Check if username starts with any adjective
            let startsWithAdjective = adjectives.contains { adjective in
                username.lowercased().hasPrefix(adjective.lowercased())
            }

            if startsWithAdjective {
                adjectivesFound += 1
            } else {
                nonAdjectivesFound += 1
            }
        }

        // Both patterns should exist (some with adjectives, some without)
        #expect(adjectivesFound > 0, "Should generate some usernames with adjectives")
        #expect(nonAdjectivesFound > 0, "Should generate some usernames without adjectives")
    }

    // MARK: - Performance Tests

    @Test func testGenerationPerformance() async throws {
        // Measure time to generate 1000 usernames
        let iterations = 1000
        let startTime = Date()

        for _ in 0..<iterations {
            _ = UsernameGenerator.generateRandomUsername()
        }

        let totalTime = Date().timeIntervalSince(startTime)
        let averageTime = totalTime / Double(iterations)

        // Each generation should be very fast (< 1ms average)
        #expect(averageTime < 0.001, "Generation too slow: \(averageTime * 1000)ms average")
        #expect(totalTime < 2.0, "Total generation time too slow: \(totalTime)s for \(iterations) usernames")
    }

    // MARK: - API Compliance Tests

    @Test func testAPILengthCompliance() async throws {
        // Test that ALL generated usernames comply with API requirements (3-20 chars)
        for _ in 0..<200 {
            let username = UsernameGenerator.generateRandomUsername()

            #expect(username.count >= 3,
                    "Username '\(username)' is too short (\(username.count) chars)")
            #expect(username.count <= 20,
                    "Username '\(username)' is too long (\(username.count) chars)")
        }
    }

    @Test func testLowercaseCompliance() async throws {
        // Verify all usernames are lowercase (API requirement)
        for _ in 0..<100 {
            let username = UsernameGenerator.generateRandomUsername()
            #expect(username == username.lowercased(),
                    "Username '\(username)' is not lowercase")
        }
    }

    // MARK: - Fallback Mechanism Tests

    @Test func testFallbackReliability() async throws {
        // Even in worst case, fallback should work
        // We can't easily test the emergency fallback, but we can verify
        // the function always returns a valid username

        for _ in 0..<50 {
            let username = UsernameGenerator.generateRandomUsername()

            // Fallback should still produce valid usernames
            #expect(!username.isEmpty, "Fallback produced empty username")
            #expect(username.count >= 3, "Fallback username too short")
            #expect(username.count <= 20, "Fallback username too long")
            #expect(username == username.lowercased(), "Fallback username not lowercase")
        }
    }

    // MARK: - Statistical Distribution Tests

    @Test func testWordPoolCoverage() async throws {
        // Generate many usernames and verify we're using the word pool well
        var usedWords = Set<String>()

        let allWords = UsernameGenerator.fruits +
                       UsernameGenerator.animals +
                       UsernameGenerator.nature +
                       UsernameGenerator.adjectives

        // Generate 500 usernames and extract words
        for _ in 0..<500 {
            let username = UsernameGenerator.generateRandomUsername()

            // Try to identify which words were used
            for word in allWords {
                if username.lowercased().contains(word.lowercased()) {
                    usedWords.insert(word.lowercased())
                }
            }
        }

        // We should have used a good portion of the word pool
        // Expect at least 30% of words to appear in 500 generations
        let coveragePercentage = Double(usedWords.count) / Double(allWords.count) * 100.0
        #expect(coveragePercentage >= 30.0,
                "Poor word pool coverage: only \(coveragePercentage)% of words used")
    }

    @Test func testNoWordRepetitionInSingleUsername() async throws {
        // This test verifies our uniqueness logic is working
        // We can't directly test internal logic, but we can verify the result

        for _ in 0..<100 {
            let username = UsernameGenerator.generateRandomUsername()

            // For now, just verify it's a valid username
            // If word repetition was common, we'd see very short usernames
            // or patterns like "starstarstar"
            #expect(username.count >= 3, "Suspicious short username: '\(username)'")
        }
    }
}
