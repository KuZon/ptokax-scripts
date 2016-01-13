

function UpdateHubtime()
	local tRegUsers = Core.GetOnlineRegs(true)
	for iIndex,tUser in ipairs(tRegUsers) do
		if (tUser.sMode == "A") then					
			UpdateTime(tUser)
		end
	end
end

function UpdateTime( tUser )
	local sNick = sqlCon:escape(tUser.sNick)
	local iFactor =1
	local sQuery = [[INSERT INTO `uptime`(`nick`,`time`)
		VALUES( '%s','%d' )
		ON DUPLICATE KEY
		UPDATE time = time + %d
		]]
	local SQLCur = assert( sqlCon:execute(string.format(sQuery, sNick, iFactor, iFactor)) )
end

function hubTime( tUser )
	local sNick = sqlCon:escape(tUser.sNick)
	local sQuery = [[SELECT * FROM `uptime` WHERE `nick`='%s']]
	tSQLResults = assert( sqlCon:execute( string.format( sQuery, sNick ) ) )
	tRow = tSQLResults:fetch ({}, "a")
	if tRow then
		if tUser.sNick == sNick then
			return conversion( tonumber( tRow.time ) )
		end
	else
		return ("Hub Time record not found for" .. tUser.sNick .."\n" )
	end

end

function topHubbers( iLimit )
	local sList = "\n\r\t\tTop Hubbers of all time on HiT Hi FiT Hai \n"
	local sQuery = [[SELECT nick,time FROM uptime ORDER BY time DESC LIMIT %d]]
	tSQLResults = assert( sqlCon:execute( string.format( sQuery, iLimit ) ) )
	tRow = tSQLResults:fetch ({}, "a")
	i=1
	while tRow do
		local iTotal = tonumber( tRow.time )
		sTemp = tRow.nick.."\t"..conversion ( iTotal )
		sList = sList..sTemp.."\n"
		tRow = tSQLResults:fetch ({}, "a")
		i = i + 1
	end
	return sList
end

function userTime( tUser )
	local sNick = sqlCon:escape(tUser.sNick)
	local sQuery = [[SELECT * FROM `uptime` WHERE `nick`='%s']]
	tSQLResults = assert( sqlCon:execute( string.format( sQuery, sNick ) ) )
	tRow = tSQLResults:fetch ({}, "a")
	if tRow then
		if tUser.sNick == sNick then
			return conversion( tonumber( tRow.time ) )
		end
	else
		return ("Hub Time record not found for" .. tUser.sNick .."\n" )
	end

end

function conversion( iTemp )
	local iTotal = tonumber( tRow.time )
	local iYear = math.floor( iTotal/( 60*24*365 ))
	local iMonth = math.floor( ( iTotal/( 60*24*30 ) )-(12*iYear))
	local iDay=math.floor( (iTotal/(60*24))-(30*iMonth)-(360*iYear) )
	local iHour = math.floor( (iTotal/60)-(24*iDay)-(30*24*iMonth)-(360*24*iYear))
	return (iYear .. " Years " ..iMonth.." Months "..iDay.." Days "..iHour.."Hours" )	
end

