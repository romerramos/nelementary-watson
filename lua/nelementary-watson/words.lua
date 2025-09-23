-- Word bank and key generation module
local translation = require("nelementary-watson.translation")
local locale = require("nelementary-watson.locale")
local utils = require("nelementary-watson.utils")

local M = {}

-- Curated word bank for generating readable keys
M.word_bank = {
	"blue", "red", "green", "yellow", "purple", "orange", "pink", "gray", "black", "white",
	"big", "small", "fast", "slow", "bright", "dark", "light", "heavy", "soft", "hard",
	"mountain", "river", "ocean", "forest", "desert", "valley", "lake", "hill", "field", "garden",
	"swift", "gentle", "calm", "wild", "quiet", "loud", "smooth", "rough", "clear", "cloudy",
	"north", "south", "east", "west", "center", "edge", "corner", "side", "top", "bottom",
	"morning", "evening", "night", "dawn", "sunset", "noon", "winter", "spring", "summer", "autumn",
	"stone", "wood", "metal", "glass", "paper", "cloth", "rope", "thread", "wire", "chain",
	"star", "moon", "sun", "cloud", "rain", "wind", "fire", "water", "earth", "air",
	"bird", "fish", "tree", "flower", "grass", "leaf", "branch", "root", "seed", "fruit",
	"book", "page", "word", "line", "text", "code", "data", "file", "path", "link",
	"home", "door", "window", "room", "wall", "floor", "roof", "bridge", "road", "path",
	"happy", "sad", "angry", "calm", "excited", "tired", "fresh", "old", "new", "young",
	"circle", "square", "triangle", "line", "curve", "point", "angle", "shape", "form", "pattern",
	"wave", "tide", "storm", "breeze", "thunder", "lightning", "rainbow", "snow", "ice", "frost",
	"key", "lock", "door", "gate", "fence", "wall", "tower", "castle", "house", "cabin",
	"ship", "boat", "plane", "train", "car", "bike", "truck", "van", "bus", "taxi",
	"apple", "orange", "banana", "grape", "cherry", "peach", "lemon", "berry", "melon", "plum",
	"cat", "dog", "horse", "cow", "sheep", "pig", "goat", "duck", "chicken", "rabbit",
	"hand", "foot", "head", "eye", "ear", "nose", "mouth", "finger", "thumb", "arm",
	"music", "song", "sound", "voice", "note", "beat", "rhythm", "melody", "harmony", "tune",
	"game", "play", "sport", "race", "match", "team", "player", "win", "lose", "score",
	"friend", "family", "child", "parent", "brother", "sister", "cousin", "uncle", "aunt", "baby",
	"work", "job", "task", "goal", "plan", "idea", "dream", "hope", "wish", "need",
	"love", "like", "hate", "fear", "joy", "peace", "hope", "trust", "faith", "care"
}

-- Generate a random 4-word key in snake_case
function M.generate_random_key()
	local selected_words = {}
	local word_count = #M.word_bank

	-- Select 4 unique words
	local used_indices = {}
	for i = 1, 4 do
		local index
		repeat
			index = math.random(1, word_count)
		until not used_indices[index]

		used_indices[index] = true
		table.insert(selected_words, M.word_bank[index])
	end

	return table.concat(selected_words, "_")
end

-- Check if a key exists in any translation file
function M.key_exists_in_translations(workspace_root, key)
	local available_locales = locale.get_available_locales(workspace_root)

	for _, locale_code in ipairs(available_locales) do
		local translations = translation.load_translations(workspace_root, locale_code)
		if translations and translations[key] then
			return true
		end
	end

	return false
end

-- Generate a unique key that doesn't exist in any translation files
function M.generate_unique_key(workspace_root)
	local max_attempts = 100
	local attempts = 0

	-- Initialize random seed
	math.randomseed(os.time())

	repeat
		local key = M.generate_random_key()
		attempts = attempts + 1

		if not M.key_exists_in_translations(workspace_root, key) then
			return key
		end
	until attempts >= max_attempts

	-- Fallback: append timestamp if we can't find a unique key
	local fallback_key = M.generate_random_key() .. "_" .. tostring(os.time())
	return fallback_key
end

return M