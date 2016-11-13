print("Loading Seat Protection")
   
if SERVER then
	include("protec/init.lua")
	AddCSLuaFile("protec/cl_init.lua")
else
	include("protec/cl_init.lua")
end