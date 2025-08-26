-- Disables map demolisher territory generation by map generator
--if not settings.startup["hexcoder-demolishers-no-initial-territory"].value then
--	data.raw['planet']['vulcanus'].map_gen_settings.territory_settings = nil
--end

-- Create invisible and inactive dummy demolisher (see-control.lua)

--local function demolisher_spritesheet(file_name, is_shadow, scale)
--	is_shadow = is_shadow or false
--	return util.sprite_load("__space-age__/graphics/entity/lavaslug/lavaslug-" .. file_name, {
--		direction_count = 128,
--		dice = 0, -- dicing is incompatible with sprite alpha masking, do not attempt
--		draw_as_shadow = is_shadow,
--		scale = scale,
--		multiply_shift = scale * 2,
--		surface = "vulcanus",
--		usage = "enemy"
--	})
--end

local function make_dummy_demolisher_head(base_name, order, dbg_sprite)
	local animation = nil

	if dbg_sprite then
		--animation = {
		--	layers = {
		--		demolisher_spritesheet("head", false, 0.5),
		--	}
		--}
		animation = {
			layers = {
				util.sprite_load("__space-age__/graphics/entity/lavaslug/lavaslug-head", {
					direction_count = 1,
					dice = 0, -- dicing is incompatible with sprite alpha masking, do not attempt
					draw_as_shadow = false,
					scale = 0.5,
					multiply_shift = 1.0,
					surface = "vulcanus",
					usage = "enemy",
					tint = { 250, 100, 100, 255 },
					tint2 = { 100, 250, 100, 255 }
				})
			}
		}
		--animation = {
		--	layers = {
		--		{
		--			filename = "__base__/graphics/entity/wooden-chest/wooden-chest.png",
		--			priority = "extra-high",
		--			width = 62,
		--			height = 72,
		--			shift = util.by_pixel(0.5, -2),
		--			scale = 1
		--		}
		--	},
		--}
	end

	return {
		name = base_name,
		localised_name = base_name,
		hidden = true,
		type = "segmented-unit",
		icon = "__space-age__/graphics/icons/small-demolisher.png",
		flags = {
			"placeable-player", "placeable-enemy", "placeable-off-grid", "breaths-air", "not-repairable",
			"not-in-kill-statistics", "not-blueprintable", "not-deconstructable", "not-on-map",
		},
		max_health = 9999999,
		order = order,
		subgroup = "enemies",
		impact_category = "organic",
		healing_per_tick = 9999999,
		is_military_target = true,
		overkill_fraction = 0.2,
		vision_distance = 0,
		territory_radius = 4,
		enraged_duration = 1,
		patrolling_speed = 0,
		investigating_speed = 0,
		attacking_speed = 0,
		enraged_speed = 0,
		acceleration_rate = 0,
		turn_radius = 12,      -- tiles
		patrolling_turn_radius = 20, -- tiles
		turn_smoothing = 0.75, -- fraction of the total turning range (based on turning radius)

		animation = animation,

		segment_engine = {
			segments = {}
		},
	}
end

local function make_dummy_demolisher(base_name, order)
	data:extend({ make_dummy_demolisher_head(base_name, order, true) })
end

make_dummy_demolisher("hexcoder-dummy-demolisher", "s-h")

-----

local function tint_demolishers()
	-- Recolor demolisher to have differing colors depending on size similar to other enemies
	local medium_tint                  = { 193, 207, 240, 255 }
	local big_tint                     = { 230, 200, 240, 255 }

	data.raw['segmented-unit']['medium-demolisher'].animation.layers[1].tint = medium_tint
	data.raw['segmented-unit']['big-demolisher'].animation.layers[1].tint    = big_tint

	function string:startswith(start)
		return self:sub(1, #start) == start
	end

	for name, val in pairs(data.raw['segment']) do
		if name:startswith("medium-demolisher-") then
			val.animation.layers[1].tint = medium_tint
		elseif name:startswith("big-demolisher-") then
			val.animation.layers[1].tint = big_tint
		end
	end
end
tint_demolishers()

-- WIP Not working!
local function avoid_demolisher_corpse_deleting_ghosts()
	-- This seems to avoid removing existing ghost entities
	data.raw['simple-entity']['small-demolisher-corpse'].collision_box = {{0,0}, {0,0}}

--[[
	function make_demolisher_dummy_corpse(base_name, order, scale)
		local corpse_tint = { 0.7, 0.7, 0.7 }
		return {
			{
				name = base_name .. "-dummy-corpse",
				localised_name = { "entity-name.demolisher-corpse", { "entity-name." .. base_name } },
				type = "simple-entity",
				flags = { "placeable-neutral", "placeable-off-grid" },
				icon = "__space-age__/graphics/icons/" .. base_name .. "-remains.png",
				subgroup = "grass",
				order = "b[decorative]-l[rock]-a[vulcanus]-g[demolisher-corpse]-" .. order,

				collision_box = { { 0, 0 }, { 0, 0 } },
				selection_box = { { 0, 0 }, { 0, 0 } },

				map_color = { 129, 105, 78 },
				count_as_rock_for_filtered_deconstruction = true,
				mined_sound = { filename = "__base__/sound/deconstruct-bricks.ogg" },
				impact_category = "stone",
				render_layer = "object",
				max_health = 2000,
				resistances =
				{
					{
						type = "fire",
						percent = 100
					}
				},
				autoplace = {
					order = "a[landscape]-c[rock]-a[huge]",
					probability_expression = "vulcanus_rock_huge"
				},
				pictures =
				{
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-05.png",
						width = 201,
						height = 179,
						scale = 1.2 * scale,
						shift = { 0.25, 0.0625 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-06.png",
						width = 233,
						height = 171,
						scale = 1.2 * scale,
						shift = { 0.429688, 0.046875 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-07.png",
						width = 240,
						height = 192,
						scale = 1.2 * scale,
						shift = { 0.398438, 0.03125 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-08.png",
						width = 219,
						height = 175,
						scale = 1.2 * scale,
						shift = { 0.148438, 0.132812 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-09.png",
						width = 240,
						height = 208,
						scale = 1.2 * scale,
						shift = { 0.3125, 0.0625 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-10.png",
						width = 243,
						height = 190,
						scale = 1.2 * scale,
						shift = { 0.1875, 0.046875 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-11.png",
						width = 249,
						height = 185,
						scale = 1.2 * scale,
						shift = { 0.398438, 0.0546875 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-12.png",
						width = 273,
						height = 163,
						scale = 1.2 * scale,
						shift = { 0.34375, 0.0390625 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-13.png",
						width = 275,
						height = 175,
						scale = 1.2 * scale,
						shift = { 0.273438, 0.0234375 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-14.png",
						width = 241,
						height = 215,
						scale = 1.2 * scale,
						shift = { 0.195312, 0.0390625 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-15.png",
						width = 318,
						height = 181,
						scale = 1.2 * scale,
						shift = { 0.523438, 0.03125 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-16.png",
						width = 217,
						height = 224,
						scale = 1.2 * scale,
						shift = { 0.0546875, 0.0234375 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-17.png",
						width = 332,
						height = 228,
						scale = 1.2 * scale,
						shift = { 0.226562, 0.046875 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-18.png",
						width = 290,
						height = 243,
						scale = 1.2 * scale,
						shift = { 0.195312, 0.0390625 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-19.png",
						width = 349,
						height = 225,
						scale = 1.2 * scale,
						shift = { 0.609375, 0.0234375 },
						tint = corpse_tint
					},
					{
						filename = "__space-age__/graphics/decorative/huge-volcanic-rock/huge-volcanic-rock-20.png",
						width = 287,
						height = 250,
						scale = 1.2 * scale,
						shift = { 0.132812, 0.03125 },
						tint = corpse_tint
					}
				}
			}
		}
	end
	
	data:extend(make_demolisher_dummy_corpse("small-demolisher", "s-h", 0.5))
	data:extend(make_demolisher_dummy_corpse("medium-demolisher", "s-i", 0.75))
	data:extend(make_demolisher_dummy_corpse("big-demolisher", "s-j", 1.0))
	
	for name, val in pairs(data.raw['segment']) do
		if name:startswith("small-demolisher-segment") then
			--local effects = val.dying_trigger_effect
			----if val.dying_trigger_effect[1].type == "create-entity" then
			--table.remove(effects, 1)
			---- This causes no corpse to appear, but somehow ghost entities are deleted anyway
			--val.dying_trigger_effect = nil
			----end
			
			val.dying_trigger_effect[1].entity_name = "small-demolisher-dummy-corpse"
		end
	end
--]]
end
avoid_demolisher_corpse_deleting_ghosts()

local function rebalance_demolisher()
	-- Phys Damage 8:
	-- Gun Turret, Red ammo DPS: 960
	
	-- Stock Demolisher Heal/s:
	-- small: 2400
	-- small: 7800
	-- small: 24000
	
	data.raw['segmented-unit']['small-demolisher' ].max_health = 30000*2 -- 30000
	data.raw['segmented-unit']['small-demolisher' ].healing_per_tick = 10 -- 40
	
	data.raw['segmented-unit']['medium-demolisher'].max_health = 100000*2 -- 100000
	data.raw['segmented-unit']['medium-demolisher'].healing_per_tick = 30 -- 130
	
	data.raw['segmented-unit']['big-demolisher'   ].max_health = 300000*2 -- 300000
	data.raw['segmented-unit']['big-demolisher'   ].healing_per_tick = 100 -- 400

	-- Resistances
	local demolisher_resistances = {
		{
			type = "explosion",
			percent = 80 -- 60
		},
		{
			type = "physical",
			percent = 75 -- 50
		},
		{ type = "fire", percent = 100 },
		{ type = "laser", percent = 100 },
		{ type = "impact", percent = 100 },
		{
			type = "poison",
			percent = 50 -- 10
		},
		{
			type = "electric",
			decrease = 20,
			percent = 70 -- 20
		}
	}
	local demolisher_body_resistances = {
		{
			type = "explosion",
			percent = 99
		},
		{
			type = "physical",
			decrease = 5, -- 5
			percent = 75 -- 50
		},
		{ type = "fire", percent = 100 },
		{ type = "laser", percent = 100 },
		{ type = "impact", percent = 100 },
		{
			type = "poison",
			percent = 50 -- 10
		},
		{
			type = "electric",
			decrease = 20,
			percent = 70 -- 20
		}
	}
	data.raw['segmented-unit']['small-demolisher' ].resistances = demolisher_resistances
	data.raw['segmented-unit']['medium-demolisher'].resistances = demolisher_resistances
	data.raw['segmented-unit']['big-demolisher'   ].resistances = demolisher_resistances
	
	for name, val in pairs(data.raw['segment']) do
		if name:startswith("small-demolisher") then
			val.max_health = data.raw['segmented-unit']['small-demolisher'].max_health
		elseif name:startswith("medium-demolisher") then
			val.max_health = data.raw['segmented-unit']['medium-demolisher'].max_health
		elseif name:startswith("big-demolisher") then
			val.max_health = data.raw['segmented-unit']['big-demolisher'].max_health
		end
		
		val.resistances = demolisher_resistances
	end
end
rebalance_demolisher()
