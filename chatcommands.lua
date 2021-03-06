minetest.register_chatcommand('chls', {
	description = 'List players on channel',
	privs = {
		interact = true,
		shout = true
	},
	func = function (name)
		channels.command_online(name)
	end,
})

minetest.register_chatcommand('join', {
	params = '<channel name>',
	description = 'join a channel',
	privs = {
		interact = true,
		shout = true
	},
	func = function (name, channel)
		channels.command_set(name, channel)
	end,
})

minetest.register_chatcommand('fjoin', {
	params = '<channel> [player]',
	description = 'Joins player to chat channel <channel>.',
	privs = {judge = true},
	func = function(name, params)
		local channel, p_name = params:match('^(%S+)%s+(.+)')
		if not channel then
			return false, 'Invalid parameters (see /help fjoin).'
		end
		if not p_name then
			p_name = name
		end
		if not minetest.auth_table[p_name] then
			return false, 'Player '..p_name..' does not exist.'
		end
		if not minetest.env:get_player_by_name(p_name) then
			return false, 'Player '..p_name..' is not online.'
		end
		if channel == 'global' or channel == 'Global' then
			channels.command_leave(p_name)
			minetest.chat_send_player(name, 'Sent '..p_name..' back to Global chat.')
		else
			channels.command_set(p_name, channel)
			minetest.chat_send_player(name,
			'Sent '..p_name..' to channel '..channel..'.')
			if name ~= p_name then
				minetest.chat_send_player(p_name, 'You have been sent to chat '..
					'channel '..channel..'. This is either because you asked, or '..
					'because you were not behaving in Global chat. To leave this '..
					'channel type /leave. To send message to Global chat type #<message>')
			end
		end

	end,
})

minetest.register_chatcommand('leave', {
	description = 'leave the channel',
	privs = {
		interact = true,
		shout = true
	},
	func = function (name)
		channels.command_leave(name)
	end,
})
--[[
minetest.register_chatcommand('channel', {
	description = 'Manages chat channels',
	privs = {
		interact = true,
		shout = true
	},
	func = function(name, param)
		if param == '' then
			minetest.chat_send_player(name, 'Online players: /channel online')
			minetest.chat_send_player(name, 'Join/switch:    /channel set <channel>')
			minetest.chat_send_player(name, 'Leave channel:  /channel leave')
			return
		elseif param == 'online' then
			channels.command_online(name)
			return
		elseif param == 'leave' then
			channels.command_leave(name)
			return
		end
		local args = param:split(' ')
		if args[1] == 'set' then
			if #args >= 2 then
				 channels.command_set(name, args[2])
				 return
			end
		end
		minetest.chat_send_player(name, 'Error: Please check again \'/channel\' for correct usage.')
	end,
})
--]]
function channels.say_chat(name, message, channel)
	minetest.log('action', 'CHAT: '..message)
	for k,v in pairs(channels.players) do
		if v == channel then --and k ~= name then
			minetest.chat_send_player(k, message)
		end
	end
end

function channels.command_online(name)
	local channel = channels.players[name]
	local players = 'You'
	if channel then
		for k,v in pairs(channels.players) do
			if v == channel and k ~= name then
				players = players..', '..k
			end
		end
	else
		local oplayers = minetest.get_connected_players()
		for _,player in ipairs(oplayers) do
			local p_name = player:get_player_name()
			if not channels.players[p_name] and p_name ~= name then
				players = players..', '..p_name
			end
		end
		return
	end
	
	minetest.chat_send_player(name, 'Online players in this channel: '..players)
end

function channels.command_set(name, param)
	if param == '' then
		minetest.chat_send_player(name, 'Error: Empty channel name')
		return
	end

	local channel_old = channels.players[name]
	if channel_old then
		if channel_old == param then
			minetest.chat_send_player(name, 'Error: You are already in this channel')
			return
		end
		channels.say_chat(name, '# '..name..' left channel '..channel_old, channel_old)
	else
		local oplayers = minetest.get_connected_players()
		for _,player in ipairs(oplayers) do
			local p_name = player:get_player_name()
			if not channels.players[p_name] and p_name ~= name then
				minetest.chat_send_player(p_name, '# '..name..' left the global chat')
			end
		end
	end

	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end

	if channels.huds[name] then
		player:hud_remove(channels.huds[name])
	end

	channels.players[name] = param
	channels.huds[name] = player:hud_add({
		hud_elem_type = 'text',
		name          = 'Channel',
		number        = 0xFFFFFF,
		position      = {x = 0.6, y = 0.03},
		text          = 'Channel: '..param,
		scale         = {x = 200,y = 25},
		alignment     = {x = 0, y = 0},
	})
	channels.say_chat('', '# '..name..' joined channel '..param, param)
	channels.command_online(name)
end

function channels.command_leave(name)
	local player = minetest.get_player_by_name(name)
	if not player then
		channels.players[name] = nil
		channels.huds[name] = nil
		return
	end

	if not (channels.players[name] and channels.huds[name]) then
		minetest.chat_send_player(name, 'Please join a channel first to leave it')
		return
	end

	if channels.players[name] then
		local channel = channels.players[name]
		channels.say_chat('', '# '..name..' left channel '..channel, channel)
		channels.players[name] = nil
	end

	if channels.huds[name] then
		player:hud_remove(channels.huds[name])
		channels.huds[name] = nil
	end
end
