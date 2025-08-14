data:extend({
	{ -- Does this have to be a startup setting?
		type = "bool-setting",
		name = "hexcoder-demolishers-no-initial-territory",
		localised_name = "Also Spawn Normal Territory",
		setting_type = "startup",
		default_value = false,
		order = "a",
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
