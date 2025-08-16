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
	local ang = cone * rand() + forw_ang - cone*0.5
	return { x=math.cos(ang), y=math.sin(ang) }
end
local function vary_random(x, variance, rand)
	-- variance = 0.2 -> x=[0.8, 1.2)
	local y = 1 + (rand()*2.0-1.0)*variance
	return x * y
end
local function viz_uniform_random_dir(surf, pos, forward, cone)
	for i=0.0,1.0,0.2 do
		local forw_ang = math.atan2(forward.y, forward.x)
		local ang = cone * i + forw_ang - cone*0.5
		local dir = { x=math.cos(ang), y=math.sin(ang) }
		
		rendering.draw_line{
			from=pos, to={ x = pos.x + dir.x*100, y = pos.y + dir.y*100 },
			color={.4,1,.4}, width=32,
			surface=surf, render_mode="chart", time_to_live=1
		}
	end
end
-- 2d direction vector to 16-way defines.direction
local function vec2direction(dir, random_offset)
	local ang = math.atan2(-dir.x, dir.y)
	local offset = random_offset or 0.0
	ang = ang + offset * (math.random()*2.0-1.0)
	return math.floor(ang / (2.0*math.pi) * 16.0 + 0.5) % 16
end

-------------------------

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
	local center = {x=0,y=0}
	local count = 0
	for _, c in pairs(terr.get_chunks()) do
		center.x = center.x + c.x*32 + 16
		center.y = center.y + c.y*32 + 16
		count = count + 1
	end
	
	return { x=center.x/count, y=center.y/count }
end
local function register_territory(terr)
	-- Create dummy demolisher if no dummy exist
	--if get_dummy_demol(terr) then return end
	local center = calc_center(terr)
	
	if not get_dummy_demol(terr) then
		game.print("Spawning dummy Demolisher")
		
		terr.surface.create_segmented_unit{
			name="hexcoder-dummy-demolisher",
			territory=terr,
			position=center,
			direction=defines.direction.north,
			extended=true
		}
	end
	
	local id = script.register_on_object_destroyed(terr)
	game.print("Territory register_on_object_destroyed id ".. id)
	storage.territories[id] = {
		obj=terr,
		center=center,
		timer=0
	}
end
script.on_event(defines.events.on_object_destroyed, function(event)
	game.print("on_object_destroyed id ".. event.registration_number)
	
	if storage.territories[event.registration_number] then
		storage.territories[event.registration_number] = nil
	end
end)
local function get_data(terr)
	local id = script.register_on_object_destroyed(terr)
	return storage.territories[id]
end

script.on_event(defines.events.on_territory_created, function(event)
	game.print("on_territory_created with ".. #event.territory.get_chunks() .." chunks")
	
end)
script.on_event(defines.events.on_territory_destroyed, function(event)
	game.print("on_territory_destroyed with ".. #event.territory.get_chunks() .." chunks")
end)

local function init_chunk(surface, chunk_area, chunk_pos)
	local has_tungsten = #surface.find_entities_filtered({
		area = chunk_area,
		type = 'resource',
		name = 'tungsten-ore',
	}) > 0
	
	if has_tungsten then
		game.print('Found tungsten in '.. surface.name .." | (".. chunk_pos.x ..", ".. chunk_pos.y ..")")
		
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

script.on_event(defines.events.on_chunk_generated, function(event)
	--game.print('Chunkgen '.. event.surface.name .." | (".. event.position.x ..", ".. event.position.y ..")")
	
	if event.surface.name == "vulcanus" then
		init_chunk(event.surface, event.area, event.position)
	end
end)

local tickrate = 60*2

script.on_event(defines.events.on_segmented_unit_died, function(event)
	local d = get_data(event.segmented_unit.territory)
	if not d then return end -- check if actually a registered territory, ie. has tungsten
	
	d.timer = settings.global["hexcoder-demolishers-spawn-time"].value * 60*60 -- min to ticks
	game.print("Timer = ".. d.timer)
end)
local function update_spawn(id, terr, d)
	--game.print("Update Territory")
	
	local first_demol = get_real_demol(terr)
	if first_demol then
		--first_demol.die()
		return
	end
	
	local timer_old = d.timer
	d.timer = d.timer - tickrate
	game.print("Timer = ".. d.timer)
	
	if d.timer > 0 then
		-- Print and or show on the map different vague (or exact) spawn times?
		-- (like low, medium and high warning symbol)
		local _30sec = 30*60
		if d.timer < _30sec then
			if timer_old >= _30sec then
				game.print("Demolisher spawning in 30 sec!")
			end
			rendering.draw_text{ text="Test Text", target=d.center,
				scale=20, color={1,1,1}, surface=terr.surface, render_mode="chart", time_to_live=tickrate }
		end
		
		return
	end
	
	-- Spawn
	d.timer = 0
	
	local chunks = terr.get_chunks()
	local idx = math.random(1, #chunks)
	
	local chunkpos = chunks[idx]
	local spawn_pos = { x=chunkpos.x*32+16, y=chunkpos.y*32+16 }
	--local spawn_dir = { x=-spawn_pos.x, y=-spawn_pos.y }
	--local center = get_terr_center(terr)
	--local spawn_pos, spawn_dir = pick_spawn_pos(center)
	--
	--local spawn_dir_enum = vec2direction({ x=-spawn_dir.x, y=-spawn_dir.y }, math.rad(30.0))
	local spawn_dir_enum = math.random(0, 15)
	
	terr.surface.create_segmented_unit{
		name="small-demolisher",
		territory=terr,
		position=spawn_pos,
		direction=spawn_dir_enum,
		extended=false
	}
	
	rendering.draw_line{ from={x=spawn_pos.x-20, y=spawn_pos.y}, to={x=spawn_pos.x+20, y=spawn_pos.y},
		color={.2,1,.2}, width=32, surface=terr.surface, render_mode="chart", time_to_live=60*10 }
	rendering.draw_line{ from={x=spawn_pos.x, y=spawn_pos.y-20}, to={x=spawn_pos.x, y=spawn_pos.y+20},
		color={.2,1,.2}, width=32, surface=terr.surface, render_mode="chart", time_to_live=60*10 }
	
	game.print("Spawning Demolisher at ("..spawn_pos.x..","..spawn_pos.y..")")
end

local function init()
	storage.territories = {}
	
	init_all_chunks()
end

script.on_init(function(event)
	-- NOTE: cannot use LuaTerritory or any other lua object as key
	-- but could probably use LuaTerritory.get_segmented_unit()[<find my dummy demolisher>].unit_number
	
	init()
end)

script.on_nth_tick(tickrate, function(event)
	--game.print("on_nth_tick---------------")
	if not storage.territories then init() end
	
	local vulcanus = game.get_surface("vulcanus")
	if vulcanus then
		for id, data in pairs(storage.territories) do
			update_spawn(id, data.obj, data)
		end
	end
end)

commands.add_command("hexcoder-demol-init", nil, function(command)
	init()
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
		
		-- TODO: should probably cache list of chunks with tungsten to avoid repeated find_entities_filtered
		local has_tungsten = #surface.find_entities_filtered({
			area = {
				{ chunkpos.x    * 32,  chunkpos.y    * 32},
				{(chunkpos.x+1) * 32, (chunkpos.y+1) * 32}
			},
			type = 'resource',
			name = 'tungsten-ore',
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
		
		log('Extend existing territory')
	else
		territory = surface.create_territory{chunks=chunks}
		
		log('Create new territory')
	end
	
	-- Add invisible and inactive dummy demolisher as a workaround to allow territories to stay visible
	-- even if no real demolishers are currently active in the territory
	-- since there seems to be no way to spawn a real demolisher and then deactivate it other than spawning them at xy=99999990 and hoping they never reach the expored map
	spawn_dummy_demolisher(territory)
end

-- Merge newly generated chunks with tungsten into existing territories
script.on_event(defines.events.on_chunk_generated, function(event)
	--game.print('Chunkgen '.. event.surface.name .." | (".. event.position.x ..", ".. event.position.y ..")")
	
	if event.surface.name == "vulcanus" then
		local has_tungsten = #event.surface.find_entities_filtered({
			area = event.area,
			type = 'resource',
			name = 'tungsten-ore',
		}) > 0
		
		if has_tungsten then
			log('Found tungsten in '.. event.surface.name .." | (".. event.position.x ..", ".. event.position.y ..")")
			
			for_tungsten_chunk(event.surface, event.position)
		end
	end
end)
]]

--script.on_event(defines.events.on_tick, function(event)
--	if not settings.global["hexcoder-demolishers-debug"].value then return end
--	local vulcanus = game.get_surface("vulcanus")
--	if not vulcanus then return end
--	
--end)
