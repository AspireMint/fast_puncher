-- digtime in seconds
local digtime = 0.05

minetest.register_on_mods_loaded(function()
	for name, ndef in pairs(minetest.registered_nodes) do
		local groups = {}
		for name, value in pairs(ndef.groups) do
			groups[name] = value
		end
		groups.dig_immediate = 1
		groups.crumbly = nil
		groups.cracky = nil
		groups.snappy = nil
		groups.choppy = nil
		groups.fleshy = nil
		groups.explody = nil
		groups.oddly_breakable_by_hand = nil

		minetest.override_item(ndef.name, {
			diggable = false,
			groups = groups
		})
	end
end)

local players = {}

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	local player_name = puncher and puncher:get_player_name() or ""
	local ndef = minetest.registered_nodes[node.name]
	if not minetest.is_protected(pos, player_name) and ( not ndef.can_dig or ndef.can_dig(pos, puncher) ) then
		players[puncher] = players[puncher] or {}
		players[puncher].pos = pos
		
		minetest.after(digtime, function()
			if players[puncher] and players[puncher].pos == pos then
				minetest.handle_node_drops(pos, { node.name }, puncher)
				minetest.remove_node(pos)
			end
		end)
	end
end)

minetest.register_on_leaveplayer(function(player)
	players[player] = nil
end)

minetest.register_globalstep(function(dtime)
	local remove_players = {}
	for player, pos in pairs(players) do
		local controls = player:get_player_control()
		if not controls.LMB then
			table.insert(remove_players, player)
		end
	end
	for i=1, #remove_players do
		players[remove_players[i]] = nil
	end
end)
