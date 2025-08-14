-- /c game.player.teleport({0, 0}, "vulcanus")
-- /c local radius=700 game.player.force.chart(game.player.surface, {{game.player.position.x-radius, game.player.position.y-radius}, {game.player.position.x+radius, game.player.position.y+radius}})

-- Random direction vector spanning <cone> angle facing towards <forward>
local function uniform_random_dir(forward, cone)
	local forw_ang = math.atan2(forward.y, forward.x)
	local ang = cone * math.random() + forw_ang - cone*0.5
	return { x=math.cos(ang), y=math.sin(ang) }
end
local function viz_uniform_random_dir(surf, pos, forward, cone)
	for i=0.0,1.0,0.1 do
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
local function vec2direction(dir)
	local ang = math.atan2(-dir.x, dir.y)
	return math.floor(ang / (2.0*math.pi) * 16.0 + 0.5) % 16
end

local terr_centers = {}
local function update_terr(terr)
	local center = {x=0,y=0}
	local count = 0
	for _, c in pairs(terr.get_chunks()) do
		center.x = center.x + c.x*32 + 16
		center.y = center.y + c.y*32 + 16
		count = count + 1
	end
	
	terr_centers[terr] = { x=center.x/count, y=center.y/count }
	
	game.print("updated Territory")
end

local function pick_spawn_pos(terr)
	local terr_center = terr_centers[terr]
	local dir_from_center = uniform_random_dir(terr_center, math.pi)
	local dist = 100
	return {
		x = dir_from_center.x * dist + terr_center.x,
		y = dir_from_center.y * dist + terr_center.y
	}, {
		x = -dir_from_center.x,
		y = -dir_from_center.y
	}
end

local function update_spawn(terr)
	for _, demol in pairs(terr.get_segmented_units()) do
		if demol.prototype.name ~= "hexocder-dummy-demolisher" then
			--existing_demol = demol
			--break
			demol.die()
		end
	end
	
	--for i=1,30 do
		--local chunkpos = terr.get_chunks()[1]
		--local spawn_pos = { x=chunkpos.x*32+16, y=chunkpos.y*32+16 }
		local spawn_pos, spawn_dir = pick_spawn_pos(terr)
		
		terr.surface.create_segmented_unit{
			name="small-demolisher",
			territory=terr,
			position=spawn_pos,
			direction=vec2direction({ x=-spawn_dir.x, y=-spawn_dir.y }),
			extended=true
		}
		
		game.print("Spawning Demolisher at ("..spawn_pos.x..","..spawn_pos.y..")")
	--end
end

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

local function spawn_dummy_demolisher(terr)
	-- Create dummy demolisher if no dummy exist
	for _, demol in pairs(terr.get_segmented_units()) do
		if demol.prototype.name == "hexocder-dummy-demolisher" then return end
	end
	
	game.print("Spawning dummy Demolisher")
	
	local chunkpos = terr.get_chunks()[1]
	local spawn_pos = { x=chunkpos.x*32+6, y=chunkpos.y*32+16 }
	--local spawn_pos = { x=-9999, y=-9999 }
	
	terr.surface.create_segmented_unit{
		name="hexocder-dummy-demolisher",
		territory=terr,
		position=spawn_pos,
		direction=defines.direction.north,
		extended=true
	}
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

-- Respawn demolishers if killed for testing
script.on_nth_tick(60*10, function(event)
	--game.print("on_nth_tick---------------")
	
	local vulcanus = game.get_surface("vulcanus")
	if not vulcanus then return end
	
	--for terr, center in pairs(terr_centers) do
	--	game.print("blah: ".. #terr.get_chunks() .."(".. center.x ..", ".. center.y ..")")
	--end
	
	for _, terr in pairs(vulcanus.get_territories()) do
		if not terr_centers[terr] then
			--game.print("nil!?: ".. #terr.get_chunks())
			update_terr(terr)
		end
		
		update_spawn(terr)
	end
end)

script.on_event(defines.events.on_territory_created, function(event)
	--game.print("on_territory_created")
end)
script.on_event(defines.events.on_territory_destroyed, function(event)
	--game.print("on_territory_destroyed")
	
	--for _, demol in pairs(event.territory.get_segmented_units()) do
	--	demol.destroy()
	--end
end)

script.on_event(defines.events.on_tick, function(event)
	if not settings.global["hexcoder-demolishers-debug"].value then return end
	local vulcanus = game.get_surface("vulcanus")
	if not vulcanus then return end
	
	for terr, center in pairs(terr_centers) do
	--for _, terr in pairs(vulcanus.get_territories()) do -- Not working, is this a different instance of territories!?
		--local center = terr_centers[terr]
		--if center then
		
		viz_uniform_random_dir(vulcanus, center, center, math.pi)
		
		rendering.draw_line{ from={x=0,y=0}, to=center, color={.7,0,.8}, width=32,
			surface=vulcanus, render_mode="chart", time_to_live=1
		}
		--end
	end
end)


