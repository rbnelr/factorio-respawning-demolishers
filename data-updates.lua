
-- Disables map demolisher territory generation by map generator
if not settings.startup["hexcoder-demolishers-no-initial-territory"].value then
	data.raw['planet']['vulcanus'].map_gen_settings.territory_settings = nil
end

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

function make_demolisher_head(base_name, order, dbg_sprite)
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
					usage = "enemy"
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
		flags = {"placeable-player", "placeable-enemy", "placeable-off-grid", "breaths-air", "not-repairable",
			"not-in-kill-statistics",
			"not-blueprintable",
			"not-deconstructable",
			"not-on-map",
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
		turn_radius = 12, -- tiles
		patrolling_turn_radius = 20, -- tiles
		turn_smoothing = 0.75, -- fraction of the total turning range (based on turning radius)
		
		animation = animation,
		
		segment_engine = {
			segments = {}
		},
		
		ac
	}
end

function make_demolisher(base_name, order)
	data:extend({make_demolisher_head(base_name, order, true)})
end

make_demolisher("hexocder-dummy-demolisher", "s-h")
