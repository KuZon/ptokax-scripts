function OnStartup()
	tConfig = {
		sPath = Core.GetPtokaXPath().."scripts/files/",
		sDepPath = "dependency/",
		sPickleFile = "pickle.lua",
		sLogPath = "/www/ChatLogs/"..os.date( "%Y/" ),
	}
	tRooms = {
		["#[Gamers]"] = {
			sBotDescription = "Gamers' lounge...",
			sBotEmail = "donot@mail.me",
			sLogFile = "games.txt",
			sSubscribersFile = tConfig.sPath.."texts/".."gameSub.txt",
			tSubscribers = { tModerators = {} }
		},
		["#[QuizRoom]"] = {
			sBotDescription = "Chatroom where quizzes are hosted.",
			sBotEmail = "do-not@mail.me",
			sLogFile = nil,
			sSubscribersFile = tConfig.sPath.."texts/".."quizSub.txt",
			tSubscribers = { tModerators = {} }
		},
		["#[Anime]"] = {
			sBotDescription = "Discusssing anime and manga",
			sBotEmail = "do.not@mail.me",
			sLogFile = "anime.txt",
			sSubscribersFile = tConfig.sPath.."texts/".."animSub.txt",
			tSubscribers = { tModerators = {} }
		},
		["#[NSFW]"] = {
			sBotDescription = "Chatroom for NSFW.",
			sBotEmail = "do.not@mail.me",
			sLogFile = "nsfw.txt",
			sSubscribersFile = tConfig.sPath.."texts/".."nsfwSub.txt",
			tSubscribers = { tModerators = {} }
		}
	}
	dofile( tConfig.sPath..tConfig.sDepPath..tConfig.sPickleFile )
	for sBotName, tInfo in pairs( tRooms ) do
		Core.RegBot( sBotName, tInfo.sBotDescription, tInfo.sBotEmail, true )
		if io.open( tInfo.sSubscribersFile, "r" ) then
			dofile( tInfo.sSubscribersFile )
			tInfo.tSubscribers = tTemp
			tTemp = nil
		end
	end
end

function ToArrival( tUser, sMessage )
	local sTo = sMessage:match( "$To: (%S+) From:" )
	if not tRooms[sTo] then return false end
	local sCmd, sData = sMessage:match( "%b<>%s+[-+*/!#?](%w+)%s?(.*)|" )
	SaveToFile( sTo, sMessage:match("%b$$(.*)|") )
	if FindSubscription( tRooms[sTo].tSubscribers, tUser.sNick ) and not sCmd then
		SendToSubscribers( tUser.sNick, sTo, sMessage )
		return true
	elseif not FindSubscription( tRooms[sTo].tSubscribers, tUser.sNick ) and not sCmd then
		Core.SendPmToUser( tUser, sTo, "You are not a part of this chatroom. Please join in to participate." )
		return false
	end
	if sData and sData:len() == 0 then sData = nil end
	if not sCmd then return false end
	if sCmd:lower() == "join" or sCmd:lower() == "subscribe" then
		if FindSubscription( tRooms[sTo].tSubscribers, tUser.sNick ) then
			Core.SendPmToUser( tUser, sTo, "You are already subscribed to this chatroom." )
			return false
		end
		table.insert( tRooms[sTo].tSubscribers, tUser.sNick )
		Core.SendPmToUser( tUser, sTo, "Your subscription was successful." )
		pickle.store( tRooms[sTo].sSubscribersFile, {tTemp = tRooms[sTo].tSubscribers} )
		return true
	elseif sCmd:lower() == "leave" or sCmd:lower() == "unsubscribe" then
		if FindSubscription( tRooms[sTo].tSubscribers, tUser.sNick ) then
			table.remove( tRooms[sTo].tSubscribers, FindSubscription(tRooms[sTo].tSubscribers, tUser.sNick) )
			Core.SendPmToUser( tUser, sTo, "Your unsubscription was successful." )
			pickle.store( tRooms[sTo].sSubscribersFile, {tTemp = tRooms[sTo].tSubscribers} )
		else
			Core.SendPmToUser( tUser, sTo, "You are not a part of this room yet." )
		end
		return true
	elseif sCmd:lower() == "kick" then
		local sKicked = sData and sData:match( "^(%S+)" )
		if not sKicked then
			Core.SendPmToUser( tUser, sTo, "No nickname was provided." )
			return false
		end
		if not FindSubscription( tRooms[sTo].tSubscribers, sKicked ) then
			Core.SendPmToUser( tUser, sTo, sKicked.." is not subscribed to this room." )
			return false
		end
		if tUser.iProfile ~= 0 and not FindSubscription( tRooms[sTo].tSubscribers.tModerators, tUser.sNick ) then
			Core.SendPmToUser( tUser, sTo, "You do not have access to this command. Kicked for abusing." )
			table.remove( tRooms[sTo].tSubscribers, FindSubscription(tRooms[sTo].tSubscribers, tUser.sNick) )
			pickle.store( tRooms[sTo].sSubscribersFile, {tTemp = tRooms[sTo].tSubscribers} )
			return false
		else
			Core.SendPmToUser( tUser, sTo, "Kicking "..sKicked.." from "..sTo.." chatroom." )
			table.remove( tRooms[sTo].tSubscribers, FindSubscription(tRooms[sTo].tSubscribers, sKicked) )
			pickle.store( tRooms[sTo].sSubscribersFile, {tTemp = tRooms[sTo].tSubscribers} )
			return false
		end
	elseif sCmd:lower() == "invite" and FindSubscription( tRooms[sTo].tSubscribers, tUser.sNick ) then
		local sGuest = sData and sData:match( "^(%S+)" )
		if not sGuest then
			Core.SendPmToUser( tUser, sTo, "No nickname was provided." )
			return false
		end
		local tGuest = Core.GetUser( sGuest )
		if tGuest then
			Core.SendPmToUser( tUser, sTo, tGuest.sNick.." has been invited to "..sTo.." chatroom." )
			Core.SendPmToUser( tGuest, sTo, "You have been invited to "..sTo.." chatroom. See help command (or use join to participate)." )
			return true
		else
			Core.SendPmToUser( tUser, sTo, "User with nick "..sGuest.." is not online." )
			return false
		end
	elseif sCmd:lower() == "l" or sCmd:lower() == "list" then
		local sTemplate = ("There are %02d current subscribers participating:\n\n\t"):format( #(tRooms[sTo].tSubscribers) )
		Core.SendPmToUser( tUser, sTo, sTemplate..table.concat(tRooms[sTo].tSubscribers, ", ") )
		return true
	elseif sCmd:lower() == "h" or sCmd:lower() == "help" then
		if tUser.iProfile ~= 0 and not FindSubscription( tRooms[sTo].tSubscribers.tModerators, tUser.sNick ) then
			Core.SendPmToUser( tUser, sTo, "The commands available are: help, list, join, invite and leave" )
			return true
		else
			Core.SendPmToUser( tUser, sTo, "The commands available are: help, list, join, invite, kick, police and leave" )
			return true
		end
	elseif sCmd:lower() == "mod" or sCmd:lower() == "police" and ('01'):find( tostring(tUser.iProfile) ) then
		local sNewMod = sData and sData:match( "^(%S+)" )
		local IsInRoom = FindSubscription( tRooms[sTo].tSubscribers, sNewMod )
		if sNewMod and IsInRoom and not FindSubscription( tRooms[sTo].tSubscribers.tModerators, sNewMod ) then
			table.insert( tRooms[sTo].tSubscribers.tModerators, sNewMod )
			local sReply = ("$To: %s From: %s $<%s> %s has been promoted to room moderator by %s.|"):format( sTo, sTo, sTo, sNewMod, tUser.sNick )
			SendToSubscribers( sTo, sTo, sReply, true )
			return true
		end
	else
		SendToSubscribers( tUser.sNick, sTo, sMessage )
		return true
	end
	return true
end

function OnExit()
	for sBotName, tInfo in pairs( tRooms ) do
		Core.UnregBot( sBotName )
	end
end

function SaveToFile( sRoomName, sChatMessage )
	if not tRooms[sRoomName].sLogFile then
		return false
	end
	local sStoreMessage, fWrite = os.date("[%Y-%m-%d %H:%M:%S] ")..sChatMessage, io.open( tConfig.sLogPath..os.date("%m/")..tRooms[sRoomName].sLogFile, "a" )
	fWrite:write( sStoreMessage.."\n" )
	fWrite:flush()
	fWrite:close()
	return true
end

function SendToSubscribers( sSelfNick, sRoomName, sIncoming, bNotice )
	local sIncoming, sRawString = sIncoming:match( "%b$$(.*)|" ), "$To: %s From: %s $%s|"
	if sRoomName == "#[NSFW]" and not bNotice then
		sIncoming = "<Anonymous>"..sIncoming:match( "%b<>(.*)" )
	end
	for iIndex, sNick in ipairs( tRooms[sRoomName].tSubscribers ) do
		if sNick:lower() ~= sSelfNick:lower() then
			Core.SendToNick( sNick, sRawString:format(sNick, sRoomName, sIncoming) )
		end
	end
	return true
end

function FindSubscription( tInputTable, sNick )
	for iIndex, sName in ipairs( tInputTable ) do
		if sNick:lower() == sName:lower() then
			return iIndex
		end
	end
	return false
end
