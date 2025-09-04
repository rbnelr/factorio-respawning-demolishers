-- /c game.player.teleport({0, 0}, "vulcanus")
-- /c local radius=700 game.player.force.chart(game.player.surface, {{game.player.position.x-radius, game.player.position.y-radius}, {game.player.position.x+radius, game.player.position.y+radius}})

-- WARNING: similar seeds generate similar numbers, so can appear not-random
local function seed2d_to_rand(pos)
	--return game.create_random_generator((pos.x % 65536) + ((pos.y % 65536) * 65536))
	return game.create_random_generator((pos.x * 7829 % 65536) + ((pos.y * 971 % 65536) * 65536))
	--return math.random
end
-- Random direction vector spanning <cone> angle facing towards <forward>
local function uniform_random_dir(forward, cone, rand)
	local forw_ang = math.atan2(forward.y, forward.x)
	local ang = cone * rand() + forw_ang - cone * 0.5
	return { x = math.cos(ang), y = math.sin(ang) }
end
local function vary_random(x, variance, rand)
	-- variance = 0.2 -> x=[0.8, 1.2)
	local y = 1 + (rand() * 2.0 - 1.0) * variance
	return x * y
end
local function viz_uniform_random_dir(surf, pos, forward, cone)
	for i = 0.0, 1.0, 0.2 do
		local forw_ang = math.atan2(forward.y, forward.x)
		local ang = cone * i + forw_ang - cone * 0.5
		local dir = { x = math.cos(ang), y = math.sin(ang) }

		rendering.draw_line {
			from = pos, to = { x = pos.x + dir.x * 100, y = pos.y + dir.y * 100 },
			color = { .4, 1, .4 }, width = 32,
			surface = surf, render_mode = "chart", time_to_live = 1
		}
	end
end
-- 2d direction vector to 16-way defines.direction
local function vec2direction(dir, random_offset)
	local ang = math.atan2(-dir.x, dir.y)
	local offset = random_offset or 0.0
	ang = ang + offset * (math.random() * 2.0 - 1.0)
	return math.floor(ang / (2.0 * math.pi) * 16.0 + 0.5) % 16
end

local function draw_cross(position, surface, width, color, render_mode, time_to_live)
	rendering.draw_line { from = { x = position.x - 20, y = position.y }, to = { x = position.x + 20, y = position.y },
		color = color, width = width, surface = surface, render_mode = render_mode, time_to_live = time_to_live }
	rendering.draw_line { from = { x = position.x, y = position.y - 20 }, to = { x = position.x, y = position.y + 20 },
		color = color, width = width, surface = surface, render_mode = render_mode, time_to_live = time_to_live }
end

-------------------------

-- Prefer to use a singular table as lua data is untyped anyway?
local function get_terr_data(terr)
	local id = script.register_on_object_destroyed(terr)
	return storage.territories[id]
end
local function get_demol_data(terr)
	local id = script.register_on_object_destroyed(terr)
	return storage.demolishers[id]
end

local function get_dummy_demol(terr)
	for _, demol in pairs(terr.get_segmented_units()) do
		if demol.prototype.name == "hexcoder-dummy-demolisher" then
			return demol
		end
	end
end
local function get_real_demol(terr)
	for _, demol in pairs(terr.get_segmented_units()) do
		if demol.prototype.name ~= "hexcoder-dummy-demolisher" then
			return demol
		end
	end
end
local function calc_center(terr)
	local center = { x = 0, y = 0 }
	local count = 0
	for _, c in pairs(terr.get_chunks()) do
		center.x = center.x + c.x * 32 + 16
		center.y = center.y + c.y * 32 + 16
		count = count + 1
	end

	return { x = center.x / count, y = center.y / count }
end

-- Called every time new chunk is generated or if all chunks are inited via mod add or command
local function register_territory(terr)
	-- Create dummy demolisher if no dummy exist
	--if get_dummy_demol(terr) then return end
	local center = calc_center(terr)

	if not get_dummy_demol(terr) then
		game.print("Spawning dummy Demolisher")

		terr.surface.create_segmented_unit {
			name = "hexcoder-dummy-demolisher",
			territory = terr,
			position = center,
			direction = defines.direction.north,
			extended = true
		}
	end

	local id = script.register_on_object_destroyed(terr)
	if not storage.territories[id] then
		storage.territories[id] = {
			obj = terr,
			center = center,
			spawn_timer = 0
		}
	else
		-- Existing territory, just update center
		storage.territories[id].center = center
	end
end

local function init_chunk(surface, chunk_area, chunk_pos)
	local has_tungsten = surface.count_entities_filtered({
		area = chunk_area,
		type = "resource",
		name = "tungsten-ore",
	}) > 0

	if has_tungsten then
		game.print("Found tungsten in " .. surface.name .. " | (" .. chunk_pos.x .. ", " .. chunk_pos.y .. ")")

		local terr = surface.get_territory_for_chunk(chunk_pos)
		if terr then
			-- make this territory one that can respawn demolishers
			register_territory(terr)
		end
	end
end

local function init_all_chunks()
	local vulcanus = game.get_surface("vulcanus")
	game.print("[Respawning Demolishers] Mod added with running game, checking all Vulcanus chunks...")

	if vulcanus then
		for chunk in vulcanus.get_chunks() do
			init_chunk(vulcanus, chunk.area, chunk)
		end
	end
end
local function init()
	storage.territories = {}
	storage.demolishers = {}

	init_all_chunks()
end

-----

script.on_event(defines.events.on_object_destroyed, function(event)
	local id = event.registration_number
	game.print("on_object_destroyed id " .. id)

	if storage.territories[id] then
		game.print("on_object_destroyed territory id " .. id)
		storage.territories[id] = nil
	end
	if storage.demolishers[id] then
		game.print("on_object_destroyed demolisher id " .. id)
		storage.demolishers[id] = nil
	end
end)
script.on_event(defines.events.on_territory_created, function(event)
	game.print("on_territory_created with " .. #event.territory.get_chunks() .. " chunks")
end)
script.on_event(defines.events.on_territory_destroyed, function(event)
	game.print("on_territory_destroyed with " .. #event.territory.get_chunks() .. " chunks")
end)
script.on_event(defines.events.on_chunk_generated, function(event)
	--game.print("Chunkgen ".. event.surface.name .." | (".. event.position.x ..", ".. event.position.y ..")")

	if event.surface.name == "vulcanus" then
		init_chunk(event.surface, event.area, event.position)
	end
end)

-- Spawn corpse manually, which was disabled in data.updates, to avoid it deleting ghosts and enabling it to auto-deconstruct
local function spawn_corpse_manually(demol)
	local num_variations = 16 -- TOOD: Make dynamic ?
	
	for _, seg in pairs(demol.segments) do
		local corpse = demol.surface.create_entity{
			--name = demol.prototype.name .. "-corpse",
			name = "hexcoder-".. demol.prototype.name .. "-corpse-".. math.random(1, num_variations),
			force = "player",
			position = seg.position,
			preserve_ghosts_and_corpses = true,
		}
		
		local inventory = corpse.get_inventory(defines.inventory.item_main)
		inventory.insert({ name="tungsten-ore", count=math.random(100, 500) })
		inventory.insert({ name="stone", count=math.random(5, 35) })
		
		corpse.operable = false -- Prevent player from opening inventory
		
		-- Note: not added to undo queue
		corpse.order_deconstruction("player")
	end
end
script.on_event(defines.events.on_segmented_unit_died, function(event)
	local front = event.segmented_unit.segments[1]
	if not front or not front.position then return end

	game.print("Demolisher died")
	spawn_corpse_manually(event.segmented_unit)
end)

local function update_spawn(id, terr, d, tickrate)
	--game.print("Update Territory")

	if not settings.global["hexcoder-demolishers-enable-spawn"].value then return end

	local first_demol = get_real_demol(terr)
	if first_demol then
		--first_demol.die()
		d.spawn_timer = 0
		return
	end

	local respawn_time = settings.global["hexcoder-demolishers-spawn-time"].value * 60 * 60 -- min to ticks
	d.spawn_timer = d.spawn_timer + tickrate
	local remain = respawn_time - d.spawn_timer

	--game.print("Timer = ".. remain)

	if remain > 0 then
		-- Print and or show on the map different vague (or exact) spawn times?
		-- (like low, medium and high warning symbol)
		local _30sec = 30 * 60
		local _1min = 60 * 60
		if remain < _30sec then
			if remain + tickrate >= _30sec then
				game.print("Demolisher spawning in 30 sec!")
			end
		end

		local text = nil
		if remain >= _1min then
			text = "" .. math.floor(remain / _1min + 0.5) .. " m"
		else
			text = "" .. math.floor(remain / 60 + 1) .. " s"
		end

		rendering.draw_text { text = "Respawn in " .. text, target = d.center,
			scale = 20, color = { 1, 1, 1 }, surface = terr.surface, render_mode = "chart", time_to_live = tickrate }
		return
	end

	-- Spawn
	d.last_spawn_time = game.tick

	local chunks = terr.get_chunks()
	local idx = math.random(1, #chunks)

	local chunkpos = chunks[idx]
	local spawn_pos = { x = chunkpos.x * 32 + 16, y = chunkpos.y * 32 + 16 }
	--local spawn_dir = { x=-spawn_pos.x, y=-spawn_pos.y }
	--local center = get_terr_center(terr)
	--local spawn_pos, spawn_dir = pick_spawn_pos(center)
	--
	--local spawn_dir_enum = vec2direction({ x=-spawn_dir.x, y=-spawn_dir.y }, math.rad(30.0))
	local spawn_dir_enum = math.random(0, 15)

	draw_cross(spawn_pos, terr.surface, 32, { .2, 1, .2 }, "chart", 60 * 10)

	game.print("Spawning Demolisher at (" .. spawn_pos.x .. "," .. spawn_pos.y .. ")")

	local demol = terr.surface.create_segmented_unit {
		name = "small-demolisher",
		territory = terr,
		position = spawn_pos,
		direction = spawn_dir_enum,
		extended = false
	}

	local id = script.register_on_object_destroyed(demol)
	storage.demolishers[id] = {
		obj = demol,
		spawn_pos = spawn_pos,
		eat_timer = 0
	}
end
local function update_demol(demol)
	if demol.prototype.name == "hexcoder-dummy-demolisher" then return end
	local d = get_demol_data(demol)
	--local terr = get_terr_data(demol.territory)
	local front = demol.segments[1]
	if not d or not front or not front.entity then return end
	local ai = demol.get_ai_state()

	-- TODO: all players?
	game.get_player(1).add_custom_alert(front.entity, { type = "entity", name = "small-demolisher" },
		"A Demolisher is hungry", true)

	text = ""
	if ai.type == defines.segmented_unit_ai_state.patrolling then
		text = "Patrolling"
	elseif ai.type == defines.segmented_unit_ai_state.investigating then
		text = "Investigating"
	elseif ai.type == defines.segmented_unit_ai_state.attacking then
		text = "Attacking"

		-- Works!
		--text = "Attacking (overridden Attacking)"
		--ai = {
		--	type = defines.segmented_unit_ai_state.investigating,
		--	destination = terr.center
		--}
		--demol.set_ai_state(ai)
	elseif ai.type == defines.segmented_unit_ai_state.Enraged_at_target then
		text = "Enraged_at_target"
	elseif ai.type == defines.segmented_unit_ai_state.Enraged_at_nothing then
		text = "Enraged_at_nothing"
	end

	local is_eating = demol.territory.surface.count_entities_filtered {
		position = front.position,
		radius = 8,
		type = "resource",
		name = "tungsten-ore",
	} > 0

	if is_eating then
		d.eat_timer = d.eat_timer + 1
	end

	local retreat_time = settings.global["hexcoder-demolishers-retreat-time"].value * 60 * 60 -- min to ticks
	if d.eat_timer >= retreat_time then
		text = "Leaving (overridden)"
		ai = {
			type = defines.segmented_unit_ai_state.investigating,
			destination = d.spawn_pos
		}
		demol.set_ai_state(ai)
	end

	text = text .. " Ate=" .. d.eat_timer

	if ai.destination then
		rendering.draw_line { from = front.entity, to = ai.destination, color = { .2, 1, .2 }, width = 2, surface = demol.surface, time_to_live = 1 }
		rendering.draw_line { from = front.entity, to = ai.destination, color = { .2, 1, .2 }, width = 8, surface = demol.surface, time_to_live = 1, render_mode = "chart" }
	end
	rendering.draw_text { text = text, target = front.entity, scale = 2, color = { 1, 1, 1 }, surface = demol.surface, time_to_live = 1 }
end

local tickrate = 60 * 2
script.on_nth_tick(tickrate, function(event)
	--game.print("on_nth_tick---------------")
	--if not storage.territories then init() end

	for id, data in pairs(storage.territories) do
		update_spawn(id, data.obj, data, tickrate)
	end
end)
-- Every tick for the moment
script.on_event(defines.events.on_tick, function(event)
	local vulcanus = game.get_surface("vulcanus")
	if vulcanus then
		for _, demol in pairs(vulcanus.get_segmented_units()) do
			update_demol(demol)
		end
	end
end)

script.on_init(function(event)
	init()
end)

-------------------------

commands.add_command("hexcoder-demol-init", nil, function(command)
	init()
end)
commands.add_command("hexcoder-demol-force-spawn", nil, function(command)
	for id, data in pairs(storage.territories) do
		data.spawn_timer = 9999999999
	end
end)

-------------------------

--[[
local function merge_connected_tungsten_chunks(surface, start_chunkpos)
	-- find currently generated chunks containing tungsten using flood fill
	local visited = {}
	local queue = {}
	local found_chunks = {}
	
	local function checked_insert (chunkpos)
		if visited[chunkpos] then return end
		
		-- TODO: should probably cache list of chunks with tungsten to avoid repeated count_entities_filtered
		local has_tungsten = surface.count_entities_filtered({
			area = {
				{ chunkpos.x    * 32,  chunkpos.y    * 32},
				{(chunkpos.x+1) * 32, (chunkpos.y+1) * 32}
			},
			type = "resource",
			name = "tungsten-ore",
		}) > 0
		
		if has_tungsten then
			table.insert(queue, chunkpos)
			table.insert(found_chunks, chunkpos)
		end
	end
	
	checked_insert(start_chunkpos)
	
	local count = 0
	local max_chunks = 40
	
	while #queue > 0 do
		if count > max_chunks then break end
		count = count + 1
		
		chunkpos = table.remove(queue, 1)
		visited[chunkpos] = true
		
		checked_insert({ x = chunkpos.x -1, y = chunkpos.y })
		checked_insert({ x = chunkpos.x +1, y = chunkpos.y })
		checked_insert({ x = chunkpos.x, y = chunkpos.y -1 })
		checked_insert({ x = chunkpos.x, y = chunkpos.y +1 })
	end
	
	return found_chunks
end

local function for_tungsten_chunk(surface, chunkpos)
	local chunks = merge_connected_tungsten_chunks(surface, chunkpos)
	
	local existing_territory = nil
	-- pick first existing territory in list of chunks
	for _, c in pairs(chunks) do
		existing_territory = surface.get_territory_for_chunk(c)
		if existing_territory then break end
	end
	
	local territory = nil
	if existing_territory then
		territory = existing_territory
		surface.set_territory_for_chunks(chunks, existing_territory)
		-- Note: Extending existing territory can leave existing territory with no chunks}
		-- game automatically will delete these territories and also delete their assigned demolishers
		
		log("Extend existing territory")
	else
		territory = surface.create_territory{chunks=chunks}
		
		log("Create new territory")
	end
	
	-- Add invisible and inactive dummy demolisher as a workaround to allow territories to stay visible
	-- even if no real demolishers are currently active in the territory
	-- since there seems to be no way to spawn a real demolisher and then deactivate it other than spawning them at xy=99999990 and hoping they never reach the expored map
	spawn_dummy_demolisher(territory)
end

-- Merge newly generated chunks with tungsten into existing territories
script.on_event(defines.events.on_chunk_generated, function(event)
	--game.print("Chunkgen ".. event.surface.name .." | (".. event.position.x ..", ".. event.position.y ..")")
	
	if event.surface.name == "vulcanus" then
		local has_tungsten = event.surface.count_entities_filtered({
			area = event.area, type = "resource", name = "tungsten-ore",
		}) > 0
		
		if has_tungsten then
			log("Found tungsten in ".. event.surface.name .." | (".. event.position.x ..", ".. event.position.y ..")")
			
			for_tungsten_chunk(event.surface, event.position)
		end
	end
end)
]]

local dbg_tickrate = 60*2

local function vis_chunks_dijstra(terr)
	-- find currently generated chunks containing tungsten using flood fill
	local visited = {}
	local queue = {}
	local chunks = {}
	
	-- Oh no
	local function hash(chunk)
		return chunk.x + 1000 + (chunk.y + 1000) * 10000
	end
	
	for _, chunk in pairs(terr.get_chunks()) do
		local has_tungsten = terr.surface.count_entities_filtered({
			area = chunk.area, type = "resource", name = "tungsten-ore",
		}) > 0
		local lava_ratio = terr.surface.count_tiles_filtered({
			area = chunk.area, name = {"lava", "lava-hot"},
		}) / (32*32)
		
		if has_tungsten then
			table.insert(queue, chunk)
			chunks[hash(chunk)] = { dist=0, pred=nil, lava_ratio=lava_ratio }
		end
	end
	
	local function order(a, b)
		return chunks[hash(a)].dist < chunks[hash(b)].dist
	end
	local function checked_insert(chunk, chunk_dist, neighbour_chunk)
		local h = hash(neighbour_chunk)
		if visited[h] or terr.surface.get_territory_for_chunk(neighbour_chunk) ~= terr then return end
		
		local val = chunks[h]
		if val == nil then
			local area = {{neighbour_chunk.x*32, neighbour_chunk.y*32}, {neighbour_chunk.x*32+32, neighbour_chunk.y*32+32}}
			local lava_ratio = terr.surface.count_tiles_filtered({
				area = area, name = {"lava", "lava-hot"},
			}) / (32*32)
			
			val = { dist = 999999999, lava_ratio=lava_ratio }
			chunks[h] = val
		end
		
		local new_dist = chunk_dist + 1 + val.lava_ratio * 2.5
		
		if new_dist < val.dist then
			table.insert(queue, neighbour_chunk)
			val.dist = new_dist
			val.pred = chunk
		end
	end
	
	local count = 0
	
	while #queue > 0 do
		if count > 1000 then break end
		count = count + 1
		
		table.sort(queue, order)
		local chunk = table.remove(queue, 1)
		local h = hash(chunk)
		if not visited[h] then
			visited[h] = true
			local chunk_dist = chunks[h].dist
			local pred = chunks[h].pred
			
			rendering.draw_text { text="".. math.floor(chunks[h].dist*100)/100, target={chunk.x*32+16, chunk.y*32+16},
				scale=20, color={ .5, 1, .5 }, surface=terr.surface, render_mode="chart", time_to_live=dbg_tickrate*20 }
			if pred then
				rendering.draw_line { from={pred.x*32+16, pred.y*32+16}, to={chunk.x*32+16, chunk.y*32+16},
					width=4, color={ .5, 1, .5 }, surface=terr.surface, render_mode="chart", time_to_live=dbg_tickrate }
			end
			
			checked_insert(chunk, chunk_dist, { x=chunk.x -1, y=chunk.y })
			checked_insert(chunk, chunk_dist, { x=chunk.x +1, y=chunk.y })
			checked_insert(chunk, chunk_dist, { x=chunk.x, y=chunk.y -1 })
			checked_insert(chunk, chunk_dist, { x=chunk.x, y=chunk.y +1 })
		end
	end
end

script.on_nth_tick(dbg_tickrate, function(event)
	if not settings.global["hexcoder-demolishers-debug"].value then return end
	local vulcanus = game.get_surface("vulcanus")
	if not vulcanus then return end
	
	for _, terr in pairs(vulcanus.get_territories()) do
		for _, c in pairs(terr.get_chunks()) do
			local p00 = { c.x*32, c.y*32 }
			local p01 = { c.x*32+32, c.y*32 }
			local p10 = { c.x*32, c.y*32+32 }
			local p11 = { c.x*32+32, c.y*32+32 }
			
			local col = { 1, 0.5, 0 }
			
			if vulcanus.get_territory_for_chunk({ c.x-1, c.y }) ~= terr then
				rendering.draw_line{ from=p00, to=p10, color=col, width = 8, surface=vulcanus, time_to_live=dbg_tickrate, render_mode="chart" }
			end
			if vulcanus.get_territory_for_chunk({ c.x+1, c.y }) ~= terr then
				rendering.draw_line{ from=p01, to=p11, color=col, width = 8, surface=vulcanus, time_to_live=dbg_tickrate, render_mode="chart" }
			end
			if vulcanus.get_territory_for_chunk({ c.x, c.y-1 }) ~= terr then
				rendering.draw_line{ from=p00, to=p01, color=col, width = 8, surface=vulcanus, time_to_live=dbg_tickrate, render_mode="chart" }
			end
			if vulcanus.get_territory_for_chunk({ c.x, c.y+1 }) ~= terr then
				rendering.draw_line{ from=p10, to=p11, color=col, width = 8, surface=vulcanus, time_to_live=dbg_tickrate, render_mode="chart" }
			end
		end
	end
	
	for c in vulcanus.get_chunks() do
		local color = { 0.2, 0.2, 0.2 }
		if vulcanus.is_chunk_generated(c) then color = { 0, 0, 1 } end
		rendering.draw_rectangle{ left_top = {c.x*32+4, c.y*32+4}, right_bottom = {c.x*32+32-4, c.y*32+32-4},
			color = color, width = 32, surface = vulcanus, time_to_live = dbg_tickrate, render_mode = "chart" }
	end
	
	for _, terr in pairs(vulcanus.get_territories()) do
		--register_territory(terr)
		--local d = get_terr_data(terr)
		--if not d.did_pathfind then
		--	d.did_pathfind = true
			vis_chunks_dijstra(terr)
			--break
		--end
	end
end)
