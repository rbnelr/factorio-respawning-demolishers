--data:extend({
--	{ -- Does this have to be a startup setting?
--		type = "bool-setting",
--		name = "hexcoder-demolishers-no-initial-territory",
--		localised_name = "Also Spawn Normal Territory",
--		setting_type = "startup",
--		default_value = false,
--		order = "a",
--	}
--})

data:extend({
	{
		type = "double-setting",
		name = "hexcoder-demolishers-bot-dmg-mult",
		localised_name = "Flying Robots Damage Multipler",
		localised_description = "How much damage bots take from Ash Clouds and Trail, default 0 to avoid tons of bots dying when flying over demolisher or the trail it leaves behind.",
		setting_type = "startup",
		default_value = 0
	}
})
data:extend({
	{
		type = "bool-setting",
		name = "hexcoder-demolishers-rebalance-demolishers",
		localised_name = "Rebalance Demolishers",
		localised_description = "Greatly Reduce Demolisher HP regen, but buff HP and resistances. This is so that defense is less about overwhelming their regen for 5 seconds and more about sustained total damage done before they destroy all your turrets.",
		setting_type = "startup",
		default_value = true
	}
})
data:extend({
	{
		type = "bool-setting",
		name = "hexcoder-demolishers-nerf-fissure",
		localised_name = "Nerf Fissure Attack",
		localised_description = "Make Fissure Attack more balanced against Buildings. Usually it can one-shot almost every building. Greatly reduced damage at distance, medium & big demolisher damage scaling and attack frequency.",
		setting_type = "startup",
		default_value = true
	}
})
data:extend({
	{
		type = "bool-setting",
		name = "hexcoder-demolishers-tint",
		localised_name = "Color Coded Demolishers",
		localised_description = "Tint Demolishers by Size similar to Biters and Pentapods",
		setting_type = "startup",
		default_value = true
	}
})

------

data:extend({
	{
		type = "bool-setting",
		name = "hexcoder-demolishers-enable-spawn",
		localised_name = "Enable Respawning",
		setting_type = "runtime-global",
		default_value = true
	}
})

data:extend({
	{
		type = "bool-setting",
		name = "hexcoder-demolishers-debug",
		localised_name = "Debug Mode",
		setting_type = "runtime-global",
		default_value = false
	}
})

data:extend({
	{
		type = "double-setting",
		name = "hexcoder-demolishers-spawn-time",
		localised_name = "Base Respawn Time (minutes)",
		setting_type = "runtime-global",
		default_value = 10
	}
})
data:extend({
	{
		type = "double-setting",
		name = "hexcoder-demolishers-retreat-time",
		localised_name = "Retreat Time (minutes)",
		setting_type = "runtime-global",
		default_value = 2
	}
})

