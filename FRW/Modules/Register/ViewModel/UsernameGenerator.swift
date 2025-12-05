//
//  UsernameGenerator.swift
//  FRW
//
//  Created by cat on 2025/11/25.
//

import Foundation

/**
 * Random username generator utility
 * Generates usernames using combinations of fruits, animals, nature words, and adjectives
 * Format: configurable number of words (default: 1 word)
 */
struct UsernameGenerator {
    static let fruits: [String] = [
        "Apple", "Apricot", "Avocado", "Banana", "Cherry", "Coconut", "Date", "Fig", "Grape", "Guava",
        "Kiwi", "Lemon", "Lime", "Mango", "Melon", "Orange", "Papaya", "Peach", "Pear", "Plum", "Pomelo",
        "Quince", "Soursop", "Currant", "Sapote", "Longan", "Durian", "Kumquat", "Lychee", "Acai",
        "Berry", "Citrus", "Olive", "Raisin", "Prune", "Cassia", "Yuzu",
    ]

    static let animals: [String] = [
        "Ant", "Bear", "Beaver", "Bee", "Bird", "Bobcat", "Buffalo", "Camel", "Cat", "Cheetah",
        "Chicken", "Cobra", "Cow", "Crab", "Deer", "Dog", "Dolphin", "Duck", "Eagle", "Falcon", "Ferret",
        "Fish", "Fox", "Frog", "Giraffe", "Goat", "Goose", "Hamster", "Hawk", "Hippo", "Horse",
        "Jaguar", "Koala", "Lemur", "Leopard", "Lion", "Lizard", "Llama", "Lobster", "Monkey", "Moose",
        "Mouse", "Octopus", "Otter", "Owl", "Panda", "Panther", "Parrot", "Penguin", "Pig", "Rabbit",
        "Raccoon", "Ram", "Rat", "Raven", "Seal", "Shark", "Sheep", "Skunk", "Sloth", "Snail", "Snake",
        "Spider", "Tiger", "Toad", "Turtle", "Whale", "Wolf", "Wombat", "Zebra", "Badger", "Bat",
        "Beetle", "Bison", "Boar", "Caribou", "Clam", "Coyote", "Crow", "Donkey", "Eel", "Emu",
        "Firefly", "Gazelle", "Gecko", "Gopher", "Grouse", "Heron", "Hyena", "Iguana", "Jackal", "Jay",
        "Koi", "Lark", "Lynx", "Magpie", "Mallard", "Mantis", "Mink", "Mole", "Moth", "Narwhal", "Newt",
        "Ocelot", "Orca", "Pelican", "Pigeon", "Quail", "Robin", "Rooster", "Salmon", "Sardine",
        "Sealion", "Shrimp", "Swan", "Termite", "Toucan", "Trout", "Vulture", "Walrus", "Weasel", "Yak",
        "Zebu", "Alpaca", "Condor", "Finch", "Hornet", "Meerkat", "Osprey", "Possum", "Puffin", "Shrew",
        "Viper", "Wasp", "Wren", "Corgi", "Husky", "Puma", "Ibis", "Crane", "Stork", "Hound", "Dingo",
        "Betta", "Cicada", "Marlin", "Cougar",
    ]

    static let nature: [String] = [
        "River", "Ocean", "Sky", "Cloud", "Rain", "Sun", "Moon", "Star", "Comet", "Breeze", "Storm",
        "Forest", "Tree", "Leaf", "Rock", "Stone", "Pebble", "Hill", "Valley", "Canyon", "Desert",
        "Sand", "Wave", "Tide", "Lake", "Pond", "Stream", "Coral", "Reef", "Glacier", "Aurora",
        "Shadow", "Light", "Flame", "Fire", "Smoke", "Mist", "Dawn", "Dusk", "Sunset", "Sunrise",
        "Field", "Garden", "Flower", "Petal", "Vine", "Root", "Branch", "Seed", "Berry", "Moss",
        "Fern", "Willow", "Oak", "Pine", "Maple", "Cedar", "Meadow", "Prairie", "Savanna", "Jungle",
        "Island", "Lagoon", "Bay", "Shore", "Cave", "Cliff", "Crystal", "Gem", "Amber", "Pearl",
        "Quartz", "Emerald", "Topaz", "Volcano", "Geyser", "Thunder", "Horizon", "Echo", "Boulder",
        "Dune", "Frost", "Galaxy", "Orbit", "Planet", "Meteor", "Cosmos", "Fjord", "Grove", "Glade",
        "Bluff", "Delta", "Estuary", "Peak", "Ridge", "Ravine", "Butte", "Mesa", "Cove", "Inlet",
        "Grotto", "Cavern", "Knoll", "Dale", "Glen", "Heath", "Moor", "Fen", "Bog", "Marsh", "Swamp",
        "Basin", "Oasis", "Tundra", "Steppe", "Taiga", "Vale", "Blaze", "Ember", "Spark", "Ash",
        "Cinder", "Flare", "Glow", "Beam", "Ray", "Haze", "Fog", "Dew", "Rime", "Snow", "Hail",
        "Sleet", "Gust", "Gale", "Zephyr", "Squall", "Tempest", "Cyclone", "Nebula", "Quasar",
        "Pulsar", "Nova", "Void", "Abyss", "Zenith", "Nadir", "Eclipse",
    ]

    static let adjectives: [String] = [
        "Brave", "Calm", "Clever", "Cool", "Cozy", "Curious", "Daring", "Eager", "Fancy", "Gentle",
        "Glowing", "Golden", "Happy", "Humble", "Jolly", "Kind", "Lively", "Lucky", "Mellow", "Mighty",
        "Noble", "Playful", "Polite", "Proud", "Quick", "Quiet", "Radiant", "Shiny", "Silly", "Smart",
        "Smiling", "Snug", "Sparkly", "Swift", "Tiny", "Vibrant", "Warm", "Witty", "Zany", "Bright",
        "Bold", "Dynamic", "Epic", "Fierce", "Gleeful", "Joyful", "Lovely", "Merry", "Neat", "Peppy",
        "Plucky", "Posh", "Relaxed", "Serene", "Smooth", "Spunky", "Sunny", "Sweet", "Thrifty",
        "Tricky", "Upbeat", "Valiant", "Zealous", "Alert", "Astute", "Chill", "Crisp", "Dapper",
        "Keen", "Lush", "Perky", "Poised", "Prime", "Pure", "Rare", "Robust", "Sage", "Sharp",
        "Sleek", "Snappy", "Solid", "Spry", "Stable", "Steady", "Stealth", "Stern", "Stout", "Suave",
        "Super", "Tender", "Tidy", "True", "Trusty", "Ultra", "Unique", "Upright", "Urbane", "Vivid",
        "Wary", "Wild", "Wise", "Agile", "Blessed", "Caring", "Cosmic", "Crafty", "Divine", "Elated",
        "Fluent", "Fresh", "Gifted", "Grand", "Heroic", "Honest", "Ideal",
    ]

    private static let allWords = fruits + animals + nature + adjectives

    /**
     * Picks a random element from an array.
     */
    private static func pick<T>(_ arr: [T]) -> T? {
        return arr.randomElement()
    }

    /**
     * Generates a random username using configurable number of words.
     * Format: [adjective]word1word2... or word1word2...
     * If any word is an adjective, it's placed first.
     * Avoids repeating the same word.
     * Ensures username is between 3-20 characters as required by the API.
     *
     * @param wordCount Number of words to use (default: 1, range: 1-5)
     * @returns A randomly generated username string (3-20 characters).
     */
    static func generateRandomUsername(wordCount: Int = 3) -> String {
        // Validate word count range
        let validWordCount = max(1, min(5, wordCount))

        // Calculate max word length based on word count to stay within 20 char limit
        let maxWordLength = 20 / validWordCount
        let shortWords = allWords.filter { $0.count <= maxWordLength }

        // Validate we have enough words to work with
        guard shortWords.count >= validWordCount else {
            #if DEBUG
            print("⚠️ UsernameGenerator: Insufficient word pool size (\(shortWords.count) words) for \(validWordCount) words")
            #endif
            // Emergency fallback with hardcoded safe words
            return generateEmergencyFallback()
        }

        var attempts = 0
        let maxAttempts = 100

        while attempts < maxAttempts {
            // Safely select unique words using Set-based approach
            guard let selectedWords = selectUniqueWords(count: validWordCount, from: shortWords) else {
                attempts += 1
                continue
            }

            var words = selectedWords
            var username = ""

            if let adjectiveIndex = words.firstIndex(where: { adjectives.contains($0) }) {
                // Put adjective first, then the other words
                let adjective = words.remove(at: adjectiveIndex)
                username = adjective + words.joined()
            } else {
                // No adjective, just concatenate in order
                username = words.joined()
            }

            // Check if username meets length requirements (3-20 chars)
            if username.count >= 3 && username.count <= 20 {
                #if DEBUG
                print("✅ UsernameGenerator: Generated username '\(username)' with \(validWordCount) word(s) on attempt \(attempts + 1)")
                #endif
                return username.lowercased()
            }

            attempts += 1
        }

        // Fallback: try to build a valid username from guaranteed short words
        #if DEBUG
        print("⚠️ UsernameGenerator: Max attempts reached, using intelligent fallback")
        #endif
        return generateIntelligentFallback(from: shortWords, wordCount: validWordCount)
    }

    /**
     * Safely selects specified number of unique words from the word pool.
     * Uses Set-based approach to avoid infinite loops.
     *
     * @param count Number of words to select
     * @param words The array of words to select from
     * @returns Array of unique words, or nil if selection fails
     */
    private static func selectUniqueWords(count: Int, from words: [String]) -> [String]? {
        guard words.count >= count else { return nil }

        var selected = Set<String>()
        var attempts = 0
        let maxAttempts = count * 10 // Safety limit scales with word count

        while selected.count < count && attempts < maxAttempts {
            if let word = pick(words) {
                selected.insert(word)
            }
            attempts += 1
        }

        return selected.count == count ? Array(selected) : nil
    }

    /**
     * Generates an intelligent fallback username that guarantees valid length.
     * Selects shortest available words to maximize chance of fitting in 20 chars.
     *
     * @param words The filtered word pool
     * @param wordCount Number of words to use
     * @returns A valid username (3-20 characters)
     */
    private static func generateIntelligentFallback(from words: [String], wordCount: Int) -> String {
        // Sort by length and take shortest unique words
        let sortedWords = words.sorted { $0.count < $1.count }
        let selectedWords = Array(Set(sortedWords.prefix(wordCount * 3))).prefix(wordCount)

        guard selectedWords.count >= wordCount else {
            return generateEmergencyFallback()
        }

        let username = selectedWords.joined()

        // Ensure it meets length requirements
        if username.count >= 3 && username.count <= 20 {
            return username.lowercased()
        } else if username.count > 20 {
            // Truncate to 20 chars, ensuring at least 3 chars
            return String(username.prefix(20)).lowercased()
        } else {
            // Too short, pad with a safe word
            let padded = username + "star"
            return String(padded.prefix(20)).lowercased()
        }
    }

    /**
     * Emergency fallback with hardcoded safe words.
     * Only used when word pool is critically insufficient.
     *
     * @returns A guaranteed valid username
     */
    private static func generateEmergencyFallback() -> String {
        let emergency = ["cool", "blue", "star"]
        let username = emergency.joined()
        #if DEBUG
        print("🚨 UsernameGenerator: Using emergency fallback '\(username)'")
        #endif
        return username.lowercased()
    }
}
