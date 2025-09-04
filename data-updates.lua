local space_age_sounds = require("__space-age__.prototypes.entity.sounds")
local explosion_animations = require("__space-age__.prototypes.entity.explosion-animations")

-- Disables map demolisher territory generation by map generator
--if not settings.startup["hexcoder-demolishers-no-initial-territory"].value then
--	data.raw["planet"]["vulcanus"].map_gen_settings.territory_settings = nil
--end

function string:startswith(start)
	return self:sub(1, #start) == start
end
function string:contains(substr)
	return string.find(self, substr, nil, true) ~= nil
end

-- Create invisible and inactive dummy demolisher (see-control.lua)
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
	log("Make Dummy Demolisher")
	data:extend({ make_dummy_demolisher_head(base_name, order, true) })
end

make_dummy_demolisher("hexcoder-dummy-demolisher", "s-h")

local function tint_demolishers()
	log("Tint Demolishers")
	
	-- Recolor demolisher to have differing colors depending on size similar to other enemies
	local small_base_tint              = { 140, 127, 127, 255 }
	local small_tint                   = { 127, 127, 127, 255 }
	local medium_tint                  = { 140, 60, 70, 255 } -- 240, 55, 85, 255
	local medium_base_tint             = { 80, 80, 80, 255 }
	local big_tint                     = { 45, 35, 50, 255 } -- 55, 15, 120, 255
	local big_base_tint                = { 60, 60, 60, 255 }
	
	local function demolisher_tint_spritesheet(file_name, scale, tint)
		return util.sprite_load("__hexcoder-respawning-demolishers__/graphics/lavaslug-" .. file_name, {
			direction_count = 128,
			dice = 0, -- dicing is incompatible with sprite alpha masking, do not attempt
			draw_as_shadow = false,
			tint_as_overlay = true,
			tint = tint,
			scale = scale,
			multiply_shift = scale * 2,
			surface = "vulcanus",
			usage = "enemy"
		})
	end
	
	local function add_tint_and_mask(entity, sprite)
		local base_tint = nil
		local tint = nil
		if entity.name:startswith("small-demolisher") then
			base_tint = small_base_tint
			tint = small_tint
		elseif entity.name:startswith("medium-demolisher") then
			base_tint = medium_base_tint
			tint = medium_tint
		else
			base_tint = big_base_tint
			tint = big_tint
		end
		
		table.insert(entity.animation.layers, 2, demolisher_tint_spritesheet(sprite, entity.animation.layers[1].scale, tint))
	end
	
	add_tint_and_mask(data.raw["segmented-unit"]["small-demolisher"], "head-mask")
	add_tint_and_mask(data.raw["segmented-unit"]["medium-demolisher"], "head-mask")
	add_tint_and_mask(data.raw["segmented-unit"]["big-demolisher"], "head-mask")

	for name, val in pairs(data.raw["segment"]) do
		if name:contains("-tail") then
			add_tint_and_mask(val, "tail-mask")
		else
			add_tint_and_mask(val, "segment-mask")
		end
	end
	
	--data.raw["segmented-unit"]["medium-demolisher"].animation.layers[1].tint = medium_tint
	--data.raw["segmented-unit"]["big-demolisher"].animation.layers[1].tint = big_tint
	--
	--for name, val in pairs(data.raw["segment"]) do
	--	if name:startswith("medium-demolisher-") then
	--		val.animation.layers[1].tint = medium_tint
	--	elseif name:startswith("big-demolisher-") then
	--		val.animation.layers[1].tint = big_tint
	--	end
	--end
end
if settings.startup["hexcoder-demolishers-tint"].value then
	tint_demolishers()
end

local function avoid_demolisher_corpse_deleting_ghosts()
	log("Avoid Demolisher Corpse deleting Ghosts")
	
	--[[ enemies.lua:
	corpse = base_name .. "-corpse", -- doesn"t work. Because not a real corpse?
	dying_trigger_effect =
	{
		{
		type = "create-entity",
		entity_name = base_name .. "-corpse"
		},
	]]--
	
	-- NOTE: changing corpse collision_box = { { 0, 0 }, { 0, 0 } }, still deletes ghosts near entity center!

	-- Remove spawned corpse to avoid it deleting ghosts, then let runtime script manually spawn it, keeping ghosts and auto-deconstructing it
	-- NOTE: just removing create-entity causes no corpse rocks to spawn, but still deletes ghosts
	-- likely because the game tries to spawn corpse, but fails due to differing entity type
	for name, val in pairs(data.raw["segmented-unit"]) do
		if name == "small-demolisher" or name == "medium-demolisher" or name == "big-demolisher" then
			val.corpse = nil
			if val.dying_trigger_effect and val.dying_trigger_effect[1].type == "create-entity" then
				table.remove(val.dying_trigger_effect, 1)
			end
		end
	end
	for name, val in pairs(data.raw["segment"]) do
		if name:startswith("small-demolisher") or name:startswith("medium-demolisher") or name:startswith("big-demolisher") then
			val.corpse = nil
			if val.dying_trigger_effect and val.dying_trigger_effect[1].type == "create-entity" then
				table.remove(val.dying_trigger_effect, 1)
			end
		end
	end
end
avoid_demolisher_corpse_deleting_ghosts()

local function add_corpse_loot(base_name, scale, tungsten_min, tungsten_max, stone_min, stone_max)
	log("Create Prototypes for increased Corpse Loot without item spilling")
	
	local corpse = data.raw["simple-entity"][base_name .."-corpse"]
	
	-- Make corpse a container instead of simply-entity so it can yield lots of tungesten
	-- while avoiding huge item spills when mined by bots
	local function create_corpse_container_variation(variation_name, picture)
		local orig_corpse = data.raw["simple-entity"][base_name .."-corpse"]
		
		return { -- Copied from enemies.lua
			name = variation_name,
			localised_name = orig_corpse.localised_name,
			type = "container",
			flags = {
				"placeable-player", "placeable-off-grid",
				"player-creation", -- Cannot be deconstructed at all without this,
				"not-repairable", "not-blueprintable",
				"no-automated-item-removal", "no-automated-item-insertion", -- Stops inserters from interacting with the inventory
				"hide-alt-info"
			},
			hidden = true,
			hidden_in_factoriopedia = true,
			
			icon = orig_corpse.icon,
			subgroup = "grass",
			order="b[decorative]-l[rock]-a[vulcanus]-g[demolisher-corpse]-".. corpse.order,
			
			collision_box = {{-3 * scale, -3 * scale}, {3 * scale, 3 * scale}},
			selection_box = {{-3 * scale, -3 * scale}, {3 * scale, 3 * scale}},
			
			-- We need this rock-container to hold many items, is overriding stack size better than just giving a large inventory_size?
			inventory_size = 2,
			inventory_type = "with_custom_stack_size",
			inventory_properties = {
				--stack_size_override = { -- Wrong syntax for dictionary?
				--	{ "tungsten-ore", 10000 },
				--	{ "stone", 10000 }
				--}
				stack_size_multiplier = 200 -- 50 Stack size of tungsten/stone -> 10k to fit
			},
			
			damaged_trigger_effect = orig_corpse.damaged_trigger_effect,
			dying_trigger_effect = orig_corpse.dying_trigger_effect,
			
			map_color = {129, 105, 78},
			--count_as_rock_for_filtered_deconstruction = true,
			minable = {
				mining_particle = "stone-particle",
				mining_time = 3,
				results = {}
			},
			mined_sound = { filename = "__base__/sound/deconstruct-bricks.ogg" },
			impact_category = "stone",
			render_layer = "object",
			max_health = 2000,
			resistances = { { type = "fire", percent = 100 } },
			autoplace = {
				order = "a[landscape]-c[rock]-a[huge]",
				probability_expression = "vulcanus_rock_huge"
			},
			picture = { layers = { picture } },
		}
	end
	
	-- Containers do not support graphics variations like rocks (simple-entity) do, so manually create a bunch of variations prototypes and pick them in script
	-- According to discord PennyJim, should avoid doing this to not run into prototype limits (unclear how high), so if actual concern could pair
	-- invisible (but still selectable/minable?) container entities with visual-only vanilla rocks (delete this one by script when other one destroyed)
	for i, picture in pairs(corpse.pictures) do
		data:extend({ create_corpse_container_variation("hexcoder-".. base_name .."-corpse-".. i, picture) })
	end
	
	corpse.minable.results = {
		{ type = "item", name = "tungsten-ore", amount_min = tungsten_min, amount_max = tungsten_max },
		{ type = "item", name = "stone", amount_min = stone_min, amount_max = stone_max },
	}
end

-- Each demolisher has ~40 Segments and my plan is to respawn them from 20min to every 2min in the extreme
-- 400 tungsten * 40 = 16k / 5 minutes -> 3.2k/min which is almost as much as a medium patch gives!
add_corpse_loot("small-demolisher",  0.5,  100, 300, 10, 60)
add_corpse_loot("medium-demolisher", 0.75, 200, 550, 20, 220)
add_corpse_loot("big-demolisher",    1,    300, 800, 30, 280)

local function rebalance_demolisher()
	log("Rebalance Demolishers")
	
	-- Phys Damage 8:
	-- Gun Turret, Red ammo DPS: 960
	
	-- Stock Demolisher Heal/s:
	-- small: 2400
	-- small: 7800
	-- small: 24000
	
	data.raw["segmented-unit"]["small-demolisher" ].max_health = 50000 -- was 30000
	data.raw["segmented-unit"]["small-demolisher" ].healing_per_tick = 10 -- was 40
	
	data.raw["segmented-unit"]["medium-demolisher"].max_health = 150000 -- was 100000
	data.raw["segmented-unit"]["medium-demolisher"].healing_per_tick = 25 -- was 130
	
	data.raw["segmented-unit"]["big-demolisher"   ].max_health = 500000 -- was 300000
	data.raw["segmented-unit"]["big-demolisher"   ].healing_per_tick = 60 -- was 400

	-- Resistances
	local demolisher_resistances = {
		{
			type = "explosion",
			percent = 60 -- 60
		},
		{
			type = "physical",
			percent = 70 -- 50
		},
		{ type = "fire", percent = 100 },
		{ type = "laser", percent = 100 },
		{ type = "impact", percent = 100 },
		{
			type = "poison",
			percent = 40 -- 10
		},
		{
			type = "electric",
			decrease = 20,
			percent = 50 -- 20
		}
	}
	local demolisher_body_resistances = {
		{
			type = "explosion",
			percent = 95
		},
		{
			type = "physical",
			decrease = 5, -- 5
			percent = 70 -- 50
		},
		{ type = "fire", percent = 100 },
		{ type = "laser", percent = 100 },
		{ type = "impact", percent = 100 },
		{
			type = "poison",
			percent = 40 -- 10
		},
		{
			type = "electric",
			decrease = 20,
			percent = 50 -- 20
		}
	}
	data.raw["segmented-unit"]["small-demolisher" ].resistances = demolisher_resistances
	data.raw["segmented-unit"]["medium-demolisher"].resistances = demolisher_resistances
	data.raw["segmented-unit"]["big-demolisher"   ].resistances = demolisher_resistances
	
	for name, val in pairs(data.raw["segment"]) do
		if name:startswith("small-demolisher") then
			val.max_health = data.raw["segmented-unit"]["small-demolisher"].max_health
		elseif name:startswith("medium-demolisher") then
			val.max_health = data.raw["segmented-unit"]["medium-demolisher"].max_health
		elseif name:startswith("big-demolisher") then
			val.max_health = data.raw["segmented-unit"]["big-demolisher"].max_health
		end
		
		val.resistances = demolisher_resistances
	end
end
if settings.startup["hexcoder-demolishers-rebalance-demolishers"].value then
	rebalance_demolisher()
end

local function adjust_flying_robots_damage()
	log("Adjust Flying Robots Damage")
	--log("smoke_with_trigger: ".. smoke_with_trigger.name)
	
	local function modify_action(smoke_with_trigger, action)
		
		if action.action_delivery and
		   action.action_delivery.target_effects then
		-- We are looking for action with contents of SA enemies.lua make_ash_cloud_trigger_effects()
			
			local effects = action.action_delivery.target_effects
			
			-- We are looking for effects with 2 entries
			--  1: nested-result.area.instant.create-sticker; no trigger_target_mask, this stops player mechsuit from flying and vehicles to slow down
			--  2: nested-result.area.instant.damage physical and fire; with area having trigger_target_mask = {"flying-robot"}, this damages bots
			for idx, effect in pairs(effects) do
				if effect.action and
				   effect.action.trigger_target_mask and #effect.action.trigger_target_mask == 1 and
				   effect.action.trigger_target_mask[1] == "flying-robot" and
				   effect.action.action_delivery and
				   effect.action.action_delivery.target_effects and
				   effect.action.action_delivery.target_effects[1].type == "damage" then
					log("Modify ".. smoke_with_trigger.name)
					--table.remove(effects, idx) -- Might not be safe since empty effects don"t work
					
					for _, dmg in pairs(effect.action.action_delivery.target_effects) do
						if dmg.type == "damage" then
							local new_damage = dmg.damage.amount * settings.startup["hexcoder-demolishers-bot-dmg-mult"].value
							log("Damage ".. dmg.damage.type .." ".. dmg.damage.amount .." -> ".. new_damage)
							dmg.damage.amount = new_damage
						end
					end
				end
			end
		end
	end
	
	for name, smoke_with_trigger in pairs(data.raw["smoke-with-trigger"]) do
		-- small-demolisher-ash-cloud, small-demolisher-ash-cloud-trail, small-demolisher-expanding-ash-cloud-1/2/3 etc.
		if name:contains("demolisher") and name:contains("ash-cloud") then
			
			if smoke_with_trigger.action and smoke_with_trigger.action.action_delivery then
				-- ash-cloud-trail: only 1 action (action = make_ash_cloud_trigger_effects)
				modify_action(smoke_with_trigger, smoke_with_trigger.action)
			else
				-- other ash-cloud: action is table of actions
				if type(smoke_with_trigger.action) == "table" then
					for _, action in pairs(smoke_with_trigger.action) do
						modify_action(smoke_with_trigger, action)
					end
				end
			end
			
		end
	end
end
adjust_flying_robots_damage()

local function rebalance_fissure_attack()
	log("Rebalance Fissure Attack")
	
	local fissure_size = 0.4
	local fissure_explosion_delay_ticks = 60
	local fissure_explosion_particles_delay_ticks = 10
	local fissure_explosion_damage_delay_ticks = 15
	local fissure_eruption_ticks = fissure_explosion_delay_ticks + fissure_explosion_damage_delay_ticks
	
	-- from enemies.lua
	-- Note: fissure attack centered on entity does over 1000 base damage
	-- and very few buildings have over 1000hp
	-- Changed so that center can still one-shot turrets, but does less damage at short range, and scale less for medium & big
	local function make_demolisher_fissure_attack(base_name, order, scale, damage_multiplier)
		return {
			{
			type = "explosion",
			name = base_name .. "-fissure",
			localised_name = {"entity-name.demolisher-fissure", {"entity-name."..base_name}},
			flags = {"not-on-map"},
			hidden = true,
			icon = "__base__/graphics/icons/small-scorchmark.png",
			order = order ,
			subgroup = "explosions",
			height = 0,
			render_layer = "ground-patch-higher2",
			created_effect =
			{
				{
				type = "direct",
				action_delivery =
				{
					type = "delayed",
					delayed_trigger = base_name .. "-fissure-explosion-delay"
				}
				},
				{
				type = "direct",
				action_delivery =
				{
					type = "delayed",
					delayed_trigger = base_name .. "-fissure-explosion-particles-delay"
				}
				},
				{
				type = "direct",
				action_delivery =
				{
					type = "delayed",
					delayed_trigger = base_name .. "-fissure-explosion-damage-delay"
				}
				}
			},
			animations = util.sprite_load("__space-age__/graphics/entity/demolisher/fissure/demolisher-crack-effect",
			{
				frame_count = 15,
				priority = "high",
				--frame_count/fissure_eruption_ticks
				animation_speed = (15) / (fissure_eruption_ticks - 9),
				draw_as_glow = true,
				scale = fissure_size * scale,
			}),
			light =
			{
				intensity = 1,
				size = 20 * scale,
				color = {r = 1.0, g = 0.5, b = 0}
			},
			light_intensity_factor_final = 1,
			light_size_factor_final = 1
			},
			{
			type = "delayed-active-trigger",
			name = base_name .. "-fissure-explosion-delay",
			delay = fissure_explosion_delay_ticks,
			action =
			{
				{
				type = "direct",
				action_delivery =
				{
					type = "instant",
					target_effects =
					{
					{
						type = "create-entity",
						entity_name = base_name .. "-fissure-explosion"
					},
					--[[ {
						type = "create-entity",
						entity_name = "crash-site-fire-smoke"
					}, ]]
					{
						type = "create-entity",
						entity_name = base_name .. "-fissure-scorchmark"
					}
					}
				}
				}
			}
			},
			{
			type = "delayed-active-trigger",
			name = base_name .. "-fissure-explosion-particles-delay",
			delay = fissure_explosion_delay_ticks + fissure_explosion_particles_delay_ticks,
			action =
			{
				{
				type = "direct",
				action_delivery =
				{
					type = "instant",
					target_effects =
					{
					{
						type = "create-particle",
						repeat_count = 14,
						particle_name = "vulcanus-lava-particle-long-life-small",
						offset_deviation =
						{
						{-1, -1},
						{1 , 1}
						},
						initial_height = 0.6,
						initial_height_deviation = 0.6,
						initial_vertical_speed = 0.08,
						initial_vertical_speed_deviation = 0.3,
						speed_from_center = 0.045,
						speed_from_center_deviation = 0.1,
						frame_speed = 1,
						frame_speed_deviation = 0,
						tail_length = 52,
						tail_length_deviation = 25,
						tail_width = 6,
						rotate_offsets = false
					},
					{
						type = "create-particle",
						repeat_count = 8,
						particle_name = "vulcanus-lava-particle-long-life-small",
						offset_deviation =
						{
						{-1, -1},
						{1 , 1}
						},
						initial_height = 0.6,
						initial_height_deviation = 0.6,
						initial_vertical_speed = 0.11,
						initial_vertical_speed_deviation = 0.3,
						speed_from_center = 0.025,
						speed_from_center_deviation = 0.1,
						frame_speed = 1,
						frame_speed_deviation = 0,
						tail_length = 86,
						tail_length_deviation = 25,
						tail_width = 10,
						rotate_offsets = false
					},
					{
						type = "create-particle",
						repeat_count = 8,
						particle_name = "vulcanus-lava-particle-long-life-small",
						offset_deviation =
						{
						{-1, -1},
						{1 , 1}
						},
						initial_height = 0.6,
						initial_height_deviation = 0.6,
						initial_vertical_speed = 0.05,
						initial_vertical_speed_deviation = 0.3,
						speed_from_center = 0.01,
						speed_from_center_deviation = 0.1,
						frame_speed = 1,
						frame_speed_deviation = 0,
						tail_length = 36,
						tail_length_deviation = 25,
						tail_width = 10,
						rotate_offsets = false
					},
					--rock
					{
						type = "create-particle",
						repeat_count = 30,
						particle_name = "vulcanus-stone-particle-smoke-small",
						offset_deviation = {{-1.3, -1.3}, {1.3, 1.3}},
						initial_height = 0,
						initial_vertical_speed = 0.1,
						initial_vertical_speed_deviation = 0.1,
						speed_from_center = 0.065,
						speed_from_center_deviation = 0.1,
						only_when_visible = true
					},
					{
						type = "create-particle",
						repeat_count = 25,
						particle_name = "vulcanus-stone-particle-smoke-medium",
						offset_deviation = {{-1.3, -1.3}, {1.3, 1.3}},
						initial_height = 0,
						initial_vertical_speed = 0.1,
						initial_vertical_speed_deviation = 0.1,
						speed_from_center = 0.065,
						speed_from_center_deviation = 0.1,
						only_when_visible = true
					},
					{
						type = "create-particle",
						repeat_count = 10,
						particle_name = "vulcanus-stone-particle-smoke-big",
						offset_deviation = {{-1.3, -1.3}, {1.3, 1.3}},
						initial_height = 0,
						initial_vertical_speed = 0.1,
						initial_vertical_speed_deviation = 0.1,
						speed_from_center = 0.065,
						speed_from_center_deviation = 0.1,
						only_when_visible = true
					},
					--smoke
					--[[
					{
						type = "create-trivial-smoke",
						repeat_count = 20,
						repeat_count_deviation = 1,
						smoke_name = "magma-eruption-ground-smoke",
						offset_deviation = {{-1.5, -1.5}, {1.5, 1.5}},
						--speed = {0, -0.5},
						initial_height = - 0.4,
						speed_from_center = 0.004,
						speed_from_center_deviation = 0.015
					},
					{
						type = "create-trivial-smoke",
						repeat_count = 10,
						smoke_name = "magma-eruption-dark-smoke",
						speed = {0, -0.8},
						speed_multiplier = 0.35,
						speed_multiplier_deviation = 0.3,
						offset_deviation = {{-1, -1}, {1, 1}},
						starting_frame = 0,
						starting_frame_deviation = 60,
						initial_height = 0.6,
						speed_from_center = 0.02,
						speed_from_center_deviation = 0.1
					},
					{
						type = "create-trivial-smoke",
						repeat_count = 6,
						smoke_name = "magma-eruption-bright-smoke",
						speed = {0, -0.5},
						speed_multiplier = 0.15,
						speed_multiplier_deviation = 0.4,
						offset_deviation = {{-1, -1}, {1, 1}},
						starting_frame = 0,
						starting_frame_deviation = 60,
						initial_height = 0.6,
						speed_from_center = 0.02,
						speed_from_center_deviation = 0.1
					},]]
					}
				}
				}
			}
			},
			{
			type = "delayed-active-trigger",
			name = base_name .. "-fissure-explosion-damage-delay",
			delay = fissure_explosion_delay_ticks + fissure_explosion_damage_delay_ticks,
			action =
			{
				{
				type = "direct",
				action_delivery =
				{
					type = "instant",
					target_effects =
					{
					{
						type = "create-entity",
						entity_name = base_name .. "-fissure-damage-explosion"
					}
					}
				}
				}
			}
			},
			{
			type = "explosion",
			name = base_name .. "-fissure-explosion",
			localised_name = {"entity-name.demolisher-fissure-explosion", {"entity-name."..base_name}},
			flags = {"not-on-map"},
			hidden = true,
			icon = "__base__/graphics/icons/explosion.png",
			order = order ,
			subgroup = "explosions",
			height = 1.5,
			animations = explosion_animations.magma_eruption(),
			sound = space_age_sounds.fissure_explosion,
			light =
			{
				intensity = 0.8,
				size = 20 * scale,
				color = {r = 1.0, g = 0.5, b = 0}
			},
			light_intensity_factor_initial = 1,
			light_size_factor_initial = 1
			},
			{
			type = "explosion",
			name = base_name .. "-fissure-damage-explosion",
			localised_name = {"entity-name.demolisher-fissure-damage-explosion", {"entity-name."..base_name}},
			flags = {"not-on-map"},
			hidden = true,
			icon = "__base__/graphics/icons/explosion.png",
			order = order ,
			subgroup = "explosions",
			height = 0,
			animations = util.empty_sprite(),
			--[[sound =   {
				aggregation =
				{
				max_count = 1,
				remove = true
				},
				audible_distance_modifier = 1.95,
				switch_vibration_data =
				{
				filename = "__base__/sound/fight/large-explosion.bnvib",
				play_for = "everything",
				gain = 0.6,
				},
				game_controller_vibration_data =
				{
				low_frequency_vibration_intensity = 0.9,
				duration = 160,
				play_for = "everything"
				},
				filename = "__base__/sound/fight/fire-impact-4.ogg",
				volume = 1.0
			},]]
			sound =
			{
				aggregation =
				{
				max_count = 1,
				remove = true
				},
				switch_vibration_data =
				{
				filename = "__base__/sound/fight/medium-explosion.bnvib",
				gain = 1.0
				},
				audible_distance_modifier = 0.5,
				variations = sound_variations("__base__/sound/fight/medium-explosion", 5, 1, volume_multiplier("main-menu", 1.2) )
			},
			created_effect =
			{
				{ -- original 2 * scale / 500 physical / 400 fire
				type = "area",
				ignore_collision_condition = true,
				radius = 1 * scale,
				action_delivery =
				{
					type = "instant",
					target_effects =
					{
					{
						type = "damage",
						damage = {amount = 400 * damage_multiplier, type = "explosion"}
					},
					{
						type = "damage",
						damage = {amount = 300 * damage_multiplier, type = "fire"}
					}
					}
				}
				},
				{ -- original 4 * scale / 75 physical / 75 fire
				type = "area",
				ignore_collision_condition = true,
				radius = 3.5 * scale,
				action_delivery =
				{
					type = "instant",
					target_effects =
					{
					{
						type = "damage",
						damage = {amount = 110 * damage_multiplier, type = "explosion"}
					},
					{
						type = "damage",
						damage = {amount = 140 * damage_multiplier, type = "fire"}
					}
					}
				}
				},
				{ -- original 7 * scale / 50 physical
				type = "area",
				ignore_collision_condition = true,
				radius = 8 * scale,
				action_delivery =
				{
					type = "instant",
					target_effects =
					{
					{
						type = "damage",
						damage = {amount = 50 * damage_multiplier, type = "fire"}
					},
					{
						type = "create-entity",
						entity_name = "explosion"
					}
					}
				}
				}
			}
			},
			{
			type = "corpse",
			name = base_name .. "-fissure-scorchmark",
			localised_name = {"entity-name.demolisher-fissure-scorchmark", {"entity-name."..base_name}},
			icon = "__base__/graphics/icons/small-scorchmark.png",
			flags = {"placeable-neutral", "not-on-map", "placeable-off-grid"},
			hidden_in_factoriopedia = true,
			collision_box = {{-1.5, -1.5}, {1.5, 1.5}},
			collision_mask = {layers={doodad=true}, not_colliding_with_itself=true},
			selection_box = {{-1, -1}, {1, 1}},
			selectable_in_game = false,
			time_before_removed = 60 * 30, -- 30 seconds
			time_before_shading_off = 60 * 30,
			--time_before_shading_off = 60 * 2,
			final_render_layer = "ground-patch-higher",
			animation_render_layer = "ground-patch-higher2",
			subgroup = "scorchmarks",
			order = order ,
			remove_on_entity_placement = false,
			remove_on_tile_placement = true,
			use_tile_color_for_ground_patch_tint = false,
			decay_frame_transition_duration = 15,
			dying_speed = 0.01,
			animation = util.sprite_load("__space-age__/graphics/entity/demolisher/fissure/demolisher-fissure-hot-fade",
			{
				frame_count = 9,
				priority = "high",
				--frame_count/fissure_eruption_ticks
				draw_as_glow = true,
				scale = fissure_size * scale,
				shift = util.by_pixel( 0, 7.0),
				frame_sequence = {1, 2, 3, 4, 5, 6, 7, 8, 9}
			}),
			decay_animation =  {
				filename = "__space-age__/graphics/entity/demolisher/fissure/demolisher-fissure-fade.png",
				width = 922,
				height = 690,
				line_length = 1,
				shift = util.by_pixel( 2, 0.0),
				scale = fissure_size * scale
			}
			}
		}
	end
	
	-- NOTE: balance damage to not increase wiht demolisher size as both frequency and size already scale, causing more damage already
	--       I think letting buildings survive 1 hit, but making second hit more likely feels better than big demolishers one-shotting everything
	-- original scale 0.5, damage 1
	local small  = make_demolisher_fissure_attack("small-demolisher" , "s-h", 0.5, 1)
	-- original scale 0.75, damage 1.5
	local medium = make_demolisher_fissure_attack("medium-demolisher", "s-i", 0.75, 1.1)
	-- original scale 1.0, damage 2.5
	local big    = make_demolisher_fissure_attack("big-demolisher"   , "s-j", 1.0, 1.25)

	local prototypes = {}
	for _, val in pairs(small) do table.insert(prototypes, val) end
	for _, val in pairs(medium) do table.insert(prototypes, val) end
	for _, val in pairs(big) do table.insert(prototypes, val) end

	for _, val in pairs(prototypes) do
		data.raw[val.type][val.name] = val
	end
	
	-- orginal cooldown 20 = 3/second
	data.raw["segmented-unit"]["small-demolisher"] .revenge_attack_parameters.cooldown = 60
	data.raw["segmented-unit"]["small-demolisher"] .revenge_attack_parameters.cooldown_deviation = 0.4 -- +/- % of cooldown ?
	data.raw["segmented-unit"]["medium-demolisher"].revenge_attack_parameters.cooldown = 50
	data.raw["segmented-unit"]["medium-demolisher"].revenge_attack_parameters.cooldown_deviation = 0.4
	data.raw["segmented-unit"]["big-demolisher"]   .revenge_attack_parameters.cooldown = 40
	data.raw["segmented-unit"]["big-demolisher"]   .revenge_attack_parameters.cooldown_deviation = 0.4
	
	-- 3 setf of offset_deviation with probability = 0.3 causes 2 explosion on the same tick, not respecting cooldown
	-- so make only one attack
	data.raw["segmented-unit"]["small-demolisher"] .revenge_attack_parameters.ammo_type.action.action_delivery.target_effects = {
		type = "create-entity",
		entity_name = "small-demolisher" .. "-fissure",
		offset_deviation = {{-4, -4}, {4, 4}},
		probability = 0.8 -- Keep a bit of randomness if attack actually happens
	}
	data.raw["segmented-unit"]["medium-demolisher"] .revenge_attack_parameters.ammo_type.action.action_delivery.target_effects = {
		type = "create-entity",
		entity_name = "medium-demolisher" .. "-fissure",
		offset_deviation = {{-4, -4}, {4, 4}},
		probability = 0.8
	}
	data.raw["segmented-unit"]["big-demolisher"] .revenge_attack_parameters.ammo_type.action.action_delivery.target_effects = {
		type = "create-entity",
		entity_name = "big-demolisher" .. "-fissure",
		offset_deviation = {{-4, -4}, {4, 4}},
		probability = 0.8
	}
end
if settings.startup["hexcoder-demolishers-nerf-fissure"].value then
	rebalance_fissure_attack()
end
