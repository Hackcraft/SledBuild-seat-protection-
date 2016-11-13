 
if !CLIENT then return end 
print("Loaded Seat Protection")
local lp = LocalPlayer()
local steamID 
local steamID64
local friends = {}
local names = {}
local freeseat = false // can anyone use your seat?
  
// Max of 20 on the freeseat
// NAMES
 
local function SendFriends(send)
	if util.GetPData( steamID, "SeatFriends", "nil" ) == "nil" then
		util.SetPData( steamID, "SeatFriends", util.TableToJSON({ lp:SteamID64() }))
	end
	friends = util.JSONToTable(util.GetPData( steamID, "SeatFriends", "nil" ))
	
	// Names
	if util.GetPData( steamID, "SeatFriendsNames", "nil" ) == "nil" then
		util.SetPData( steamID, "SeatFriendsNames", util.TableToJSON({ lp:Nick() })) // no support for commas :(
	end
	names = util.JSONToTable(util.GetPData( steamID, "SeatFriendsNames", "nil" ))
	
	// Should freeseat
	if util.GetPData( steamID, "SeatFriendsWhitelist", "nil" ) == "nil" then
		util.SetPData( steamID, "SeatFriendsWhitelist", "true")
	end
	freeseat = tobool(util.GetPData( steamID, "SeatFriendsWhitelist", "nil" )) // this always has a value
	
	// Send to server
	if send then
		net.Start("SeatSettingsUpdate")
		if !freeseat then
			net.WriteTable(friends)
		else
			net.WriteTable({freeseat = true}) // weird way to do it but the server thinks it's the other way around
		end
		net.SendToServer()
	end
end

local function addFrind(ply)
	table.insert(friends, ply:SteamID64())
	table.insert(names, ply:Nick())
	util.SetPData( steamID, "SeatFriendsNames", util.TableToJSON(names))
	util.SetPData( steamID, "SeatFriends", util.TableToJSON(friends))
	SendFriends(true)
end

local function removeFriend(id)
	for k, v in pairs(friends) do
		if v == id then
			table.remove(friends, k)
			table.remove(names, k)
			util.SetPData( steamID, "SeatFriendsNames", util.TableToJSON(names))
			util.SetPData( steamID, "SeatFriends", util.TableToJSON(friends))
			SendFriends(true)
		end
	end
end

timer.Create("AnotherLP", 1, 0, function()
	if LocalPlayer() != nil and IsValid(LocalPlayer()) then
		lp = LocalPlayer()
		steamID = lp:SteamID()
		steamID64 = lp:SteamID64()
		SendFriends(true)
		timer.Destroy("AnotherLP")
	end
end)

local function AddFriends()

	local Frame = vgui.Create( "DFrame" )
	Frame:SetSize( 500, 400 )
	Frame:Center()
	Frame:SetTitle( "Add friends!" )
	Frame:SetVisible( true )
	Frame:SetDraggable( false )
	Frame:ShowCloseButton( true )
	Frame:MakePopup()
	function Frame:Paint(w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 72, 72, 72 ) )
		draw.SimpleText( "-Online Players-", "Trebuchet18", w/2, 130, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	
	local AppList = vgui.Create( "DListView", Frame )
	AppList:SetSize(490, 250)
	AppList:SetPos(5, 145)
	AppList:SetMultiSelect( false )
	AppList:AddColumn( "Name" )
	AppList:AddColumn( "SteamID64" )
	
	local players = player.GetAll()
	for i=1, #players do
		if IsValid(players[i]) then
			if !table.HasValue(friends, players[i]:SteamID64()) then
				AppList:AddLine( players[i]:Nick(), players[i]:SteamID64() )
			end
		end
	end
	
	local DermaButton = vgui.Create( "DButton", Frame )			
	DermaButton:SetText( "Add player" )				
	DermaButton:SetPos( 370, 120 )			
	DermaButton:SetSize( 125, 20 )				 
	DermaButton.DoClick = function()	
		if AppList:GetSelectedLine() then
--			print(AppList:GetLine(AppList:GetSelectedLine()):GetValue(2))
			local selected = player.GetBySteamID64(AppList:GetLine(AppList:GetSelectedLine()):GetValue(2))
			if !selected then return end
			if #friends >= 21 then // You can bypass this to possibly add more friends, I've done this because I don't know how big of a table you can send.
				chat.AddText(Color(0,255,157), "[Sledbuild] ", Color(255,255,255), "You are only allowed 20 people on your seat list.")
			else
				addFrind(selected)
				AppList:RemoveLine( AppList:GetSelectedLine() )	
				chat.AddText(Color(0,255,157), "[Sledbuild] ", Color(255,255,255), "Added " .. selected:Nick() .. " to the sitting list.")
			end
		end
	end
	
end

local function OpenSeatDerma()

	local Frame = vgui.Create( "DFrame" )
	Frame:SetSize( 500, 400 )
	Frame:Center()
	Frame:SetTitle( "Seat Settings!" )
	Frame:SetVisible( true )
	Frame:SetDraggable( false )
	Frame:ShowCloseButton( true )
	Frame:MakePopup()
	function Frame:Paint(w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 72, 72, 72 ) )
		draw.SimpleText( "-People who are allowed to use your seats-", "Trebuchet18", w/2, 130, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	
	local AppList = vgui.Create( "DListView", Frame )
	AppList:SetSize(490, 250)
	AppList:SetPos(5, 145)
	AppList:SetMultiSelect( false )
	AppList:AddColumn( "Name" )
	AppList:AddColumn( "SteamID64" )
	
	local changed = 0
	local steamid64
	for i=1, #friends do
		// See if their name changed, if so update it!
		if player.GetBySteamID64(friends[i]) then
			local friend = player.GetBySteamID64(friends[i])
			if friend:Nick() != names[i] then
				names[i] = friend:Nick()
				changed = changed + 1
			end
		end
//		if friends[i] != steamID64 then
			AppList:AddLine( names[i], friends[i] )
//		end
	end
	
	if changed > 0 then
		// Update here
		SendFriends(false) // no need to re-send to the server, we are the only ones to keep the names
	end
	
	local DermaCheckbox = vgui.Create("DCheckBoxLabel", Frame)
	DermaCheckbox:SetPos(5, 30)
	DermaCheckbox:SetValue(freeseat)
	DermaCheckbox:SetText("Allow anyone to sit in my seats.")
	function DermaCheckbox:OnChange( bVal )
		if ( bVal ) then
--			print( "Checked!" )
			util.SetPData( steamID, "SeatFriendsWhitelist", "true")
			SendFriends(true)
			// Update here
		else
--			print( "Unchecked!" )
			util.SetPData( steamID, "SeatFriendsWhitelist", "false")
			SendFriends(true)
			// Update here
		end
	end	
	
	local DermaButton = vgui.Create( "DButton", Frame )			
	DermaButton:SetText( "Kick everyone out of my seats." )				
	DermaButton:SetPos( 5, 50 )			
	DermaButton:SetSize( 176, 30 )				 
	DermaButton.DoClick = function()			 
		net.Start("SeatSettingsKick")
		net.SendToServer()
	end
	
	local DermaButton = vgui.Create( "DButton", Frame )			
	DermaButton:SetText( "Add player" )				
	DermaButton:SetPos( 370, 120 )			
	DermaButton:SetSize( 125, 20 )				 
	DermaButton.DoClick = function()			 
		AddFriends()	
	end
	
	local removed_friends = 0
	local DermaButton = vgui.Create( "DButton", Frame )			
	DermaButton:SetText( "Remove selected player" )				
	DermaButton:SetPos( 5, 120 )			
	DermaButton:SetSize( 125, 20 )				 
	DermaButton.DoClick = function()		
		if AppList:GetSelectedLine() then
			local number = AppList:GetSelectedLine() - removed_friends
			chat.AddText(Color(0,255,157), "[Sledbuild] ", Color(255,255,255), "Removed " .. names[number] .. " from the sitting list.")
			removeFriend(friends[number])
			AppList:RemoveLine( AppList:GetSelectedLine() )
			removed_friends = removed_friends + 1
		end
	end
	
	local DermaButton = vgui.Create( "DButton", Frame )			
	DermaButton:SetText( "Refresh" )				
	DermaButton:SetPos( 430, 30 )			
	DermaButton:SetSize( 60, 20 )				 
	DermaButton.DoClick = function()		
		Frame:Close()
		OpenSeatDerma()
	end
	
	local DermaButton = vgui.Create( "DButton", Frame )			
	DermaButton:SetText( "Selected player's profile" )				
	DermaButton:SetPos( 5, 95 )			
	DermaButton:SetSize( 125, 20 )				 
	DermaButton.DoClick = function()
		if AppList:GetSelectedLine() then
			gui.OpenURL("http://steamcommunity.com/profiles/" .. friends[AppList:GetSelectedLine()])	
		end
	end
	
	
end
 
concommand.Add("seat_menu", OpenSeatDerma)

hook.Add( "OnPlayerChat", "SeatFriends:D", function( ply, strText, bTeam, bDead )

	strText = string.lower( strText ) 

	if ( strText == "!seat" or strText == "!seats" ) then 
		if ply == lp then
			OpenSeatDerma()
		end
		return true 
	end

end )
