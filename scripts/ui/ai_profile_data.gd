extends Node

const PROFILES = [
    {
        "id": "ravi",
        "name": "Ravi",
        "nickname": "The Rookie",
        "level": 1,
        "tier_name": "ROOKIE",
        "tier_color": "#2ECC71",
        "specialty": "Straight Shots",
        "description": "Simple and reliable beginner. Ravi relies on clean, direct shots. Dangerous when the path is clear, but struggles with bank angles.",
        "avatar_path": "res://assets/avatars/level1_ravi.png",
        "default_unlocked": true
    },
    {
        "id": "karthik",
        "name": "Karthik",
        "nickname": "The Opportunist",
        "level": 1,
        "tier_name": "ROOKIE",
        "tier_color": "#2ECC71",
        "specialty": "Easy Pocket Selection",
        "description": "Scans the board for the simplest scoring pockets. Avoids contested center coins.",
        "avatar_path": "res://assets/avatars/level1_karthik.png",
        "default_unlocked": false
    },
    {
        "id": "arjun",
        "name": "Arjun",
        "nickname": "The Power Player",
        "level": 1,
        "tier_name": "ROOKIE",
        "tier_color": "#2ECC71",
        "specialty": "Power Control",
        "description": "Relies on heavy-impact shots to break clusters, though occasionally overpowers simple putts.",
        "avatar_path": "res://assets/avatars/level1_arjun.png",
        "default_unlocked": false
    },
    {
        "id": "vikram",
        "name": "Vikram",
        "nickname": "The Banker",
        "level": 2,
        "tier_name": "SKILLED",
        "tier_color": "#3498DB",
        "specialty": "Bank/Rebound Shots",
        "description": "Excels at single-cushion rebounds. Looks for indirect routes to bypass blockers.",
        "avatar_path": "res://assets/avatars/level2_vikram.png",
        "default_unlocked": false
    },
    {
        "id": "nikhil",
        "name": "Nikhil",
        "nickname": "The Sniper",
        "level": 2,
        "tier_name": "SKILLED",
        "tier_color": "#3498DB",
        "specialty": "Target Precision",
        "description": "Carefully aims for micro-angles and thin cuts into corner pockets.",
        "avatar_path": "res://assets/avatars/level2_nikhil.png",
        "default_unlocked": false
    },
    {
        "id": "surya",
        "name": "Surya",
        "nickname": "The Collector",
        "level": 2,
        "tier_name": "SKILLED",
        "tier_color": "#3498DB",
        "specialty": "Coin Collection",
        "description": "Prioritizes pocketing clusters and building score runs systematically.",
        "avatar_path": "res://assets/avatars/level2_surya.png",
        "default_unlocked": false
    },
    {
        "id": "dev",
        "name": "Dev",
        "nickname": "The Strategist",
        "level": 3,
        "tier_name": "ADVANCED",
        "tier_color": "#F1C40F",
        "specialty": "Strategic Shot Selection",
        "description": "Thinks multiple turns ahead, setting up future scoring runs while denying easy rebounds.",
        "avatar_path": "res://assets/avatars/level3_dev.png",
        "default_unlocked": false
    },
    {
        "id": "ajay",
        "name": "Ajay",
        "nickname": "The Defender",
        "level": 3,
        "tier_name": "ADVANCED",
        "tier_color": "#F1C40F",
        "specialty": "Defensive Play",
        "description": "Pins opponent coins against baselines and prioritizes safe positioning over risky pots.",
        "avatar_path": "res://assets/avatars/level3_ajay.png",
        "default_unlocked": false
    },
    {
        "id": "manoj",
        "name": "Manoj",
        "nickname": "The Risk Taker",
        "level": 3,
        "tier_name": "ADVANCED",
        "tier_color": "#F1C40F",
        "specialty": "Aggressive Shots",
        "description": "Willing to take difficult, high-reward cuts across the center circle.",
        "avatar_path": "res://assets/avatars/level3_manoj.png",
        "default_unlocked": false
    },
    {
        "id": "raj",
        "name": "Raj",
        "nickname": "The Trickster",
        "level": 4,
        "tier_name": "EXPERT",
        "tier_color": "#E67E22",
        "specialty": "Advanced Bank Shots",
        "description": "Masters multi-cushion angles and unexpected carom rebounds.",
        "avatar_path": "res://assets/avatars/level4_raj.png",
        "default_unlocked": false
    },
    {
        "id": "vishal",
        "name": "Vishal",
        "nickname": "The Wall",
        "level": 4,
        "tier_name": "EXPERT",
        "tier_color": "#E67E22",
        "specialty": "Defensive & Position Control",
        "description": "Combines relentless defensive blocking with precise baseline striker placement.",
        "avatar_path": "res://assets/avatars/level4_vishal.png",
        "default_unlocked": false
    },
    {
        "id": "aditya",
        "name": "Aditya",
        "nickname": "The Tactician",
        "level": 4,
        "tier_name": "EXPERT",
        "tier_color": "#E67E22",
        "specialty": "Queen & Endgame Strategy",
        "description": "Flawlessly times queen covers and endgame piece management under pressure.",
        "avatar_path": "res://assets/avatars/level4_aditya.png",
        "default_unlocked": false
    },
    {
        "id": "aryan",
        "name": "Aryan",
        "nickname": "The Master",
        "level": 5,
        "tier_name": "MASTER",
        "tier_color": "#9B59B6",
        "specialty": "Precision + Strategy",
        "description": "Combines pinpoint shot placement with optimal risk-reward path calculations.",
        "avatar_path": "res://assets/avatars/level5_aryan.png",
        "default_unlocked": false
    },
    {
        "id": "kabir",
        "name": "Kabir",
        "nickname": "The Challenger",
        "level": 5,
        "tier_name": "MASTER",
        "tier_color": "#9B59B6",
        "specialty": "Adaptive Aggression",
        "description": "Rapidly detects opponent weak spots and increases shot pace to force errors.",
        "avatar_path": "res://assets/avatars/level5_kabir.png",
        "default_unlocked": false
    },
    {
        "id": "veer",
        "name": "Veer",
        "nickname": "The Legend",
        "level": 5,
        "tier_name": "MASTER",
        "tier_color": "#9B59B6",
        "specialty": "Complete Adaptive Gameplay",
        "description": "Fully dynamic playstyle adapting between tight defense and master-level bank finishes.",
        "avatar_path": "res://assets/avatars/level5_veer.png",
        "default_unlocked": false
    }
]

static func get_profile(id: String) -> Dictionary:
	for p in PROFILES:
		if p["id"] == id:
			return p
	return {}
