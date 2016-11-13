--if !SERVER then return end
print("Loaded Seat Protection")
 
util.AddNetworkString("SeatSettingsUpdate")
util.AddNetworkString("SeatSettingsKick")

local seat = {}
local lastPressed = {}
local kicked = {}

hook.Add("CanPlayerEnterVehicle", "Protection", function(ply, vehicle)
    if IsValid(vehicle) then
		local owner = vehicle:CPPIGetOwner() or vehicle:GetOwner() or false
		if owner and IsValid(owner) and seat[owner] != nil then
			if kicked[ply] != nil then
				if kicked[ply] + 5 < CurTime() then
					SendChat(ply, Color(0,255,157), "[Sledbuild] ", "You do not have permission to use " .. owner:Nick() .. "'s seat." )
					return false
				else
					kicked[ply] = nil
				end
			end
			// If all can take a seat
			if seat[owner] == true then
				return // let them enter
			else
				// If they're in the friend list
				if seat[owner][ply:SteamID64()] != nil then
					return
				else
					SendChat(ply, Color(0,255,157), "[Sledbuild] ", "You do not have permission to use " .. owner:Nick() .. "'s seat." )
					return false
				end
			end
		end
	end
end)

net.Receive("SeatSettingsUpdate", function(len, ply)
	local t = net.ReadTable()
	if t.freeseat != nil and t.freeseat == true then
		seat[ply] = true
	else
		// convert table
		local newTable = {}
		for k, v in pairs(t) do
			newTable[v] = true
		end
		seat[ply] = newTable
	end
end)

net.Receive("SeatSettingsKick", function(len, ply)
	for k, v in ipairs(ents.FindByClass("prop_vehicle_prisoner_pod")) do
		local owner = v:CPPIGetOwner() or v:GetOwner() or false
		if owner and IsValid(owner) and owner == ply then
			 if IsValid(v) and v:IsVehicle() and v.GetPassenger and IsValid(v:GetPassenger(1)) then
				kicked[v:GetPassenger(1)] = CurTime()
				v:GetPassenger(1):ExitVehicle()
			end
		end
	end
end)
