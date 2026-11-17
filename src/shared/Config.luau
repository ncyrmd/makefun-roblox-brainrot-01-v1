-- Brainrot Bay: every tunable number in one place.
-- The economy, the conveyor, stealing, locks, rebirths and the storm all read
-- their numbers from here, so the game is balanced by editing this one file.

local Config = {}

-- Economy
Config.STARTING_CASH = 100 -- cash every player starts with
Config.BASE_SLOTS = 6 -- brainrot slots on each player's base
Config.MAX_BASES = 4 -- player bases built into the world
Config.INCOME_TICK_SECONDS = 1 -- money is paid out this often

-- Conveyor (the central walkway brainrots travel down)
Config.CONVEYOR_START_X = -56
Config.CONVEYOR_END_X = 56
Config.CONVEYOR_Y = 2.5
Config.CONVEYOR_SPEED = 6 -- studs per second
Config.SPAWN_INTERVAL = 4 -- seconds between new conveyor brainrots
Config.MAX_CONVEYOR_BRAINROTS = 8

-- Stealing and base locks
Config.STEAL_COOLDOWN = 20 -- seconds between one player's steals
Config.LOCK_COST = 500 -- cash to lock your base
Config.LOCK_DURATION = 60 -- seconds a lock lasts

-- Rebirths: cost grows with each rebirth, each rebirth adds a permanent bonus.
Config.REBIRTH_BASE_COST = 100000
Config.REBIRTH_COST_GROWTH = 2.5 -- cost multiplier per rebirth owned
Config.REBIRTH_MULTIPLIER_BONUS = 0.25 -- +25% income per rebirth, stacks

-- Brainrot Storm hazard: a warning, then the storm itself.
Config.HAZARD_INTERVAL = 90 -- seconds of calm between storms
Config.HAZARD_WARNING_SECONDS = 10 -- warning before the storm hits
Config.HAZARD_DURATION = 20 -- seconds the storm lasts
Config.HAZARD_INCOME_MULTIPLIER = 2 -- income doubles during a storm
Config.HAZARD_WALK_SPEED = 8 -- WalkSpeed during a storm (normal is 16)

return Config
