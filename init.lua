channels = {}
channels.huds = {}
channels.players = {}

dofile(minetest.get_modpath("channels").."/chatcommands.lua")

minetest.register_on_chat_message(function(name, message)
	local pl_channel = channels.players[name]
	if not pl_channel then
		return false
	end
	if pl_channel == "" then
		channels.players[name] = nil
		return false
	end

	if string.find(message,"^#") then
		message = string.match(message,"^#(.+)")
		minetest.log("action", "CHAT: <"..name.."> "..message)
		minetest.chat_send_all("<"..name.."> "..message)
	else
		channels.say_chat(name, pl_channel..": <"..name.."> "..message, pl_channel)
	end
	return true
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	channels.players[name] = nil
	channels.huds[name] = nil
end)
