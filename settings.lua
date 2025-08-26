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
