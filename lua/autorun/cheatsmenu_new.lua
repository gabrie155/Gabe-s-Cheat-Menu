if SERVER then --all code here is server sided
    -- Create ConVars for the force settings
    local teleportEnabledConVar = CreateConVar("cheat_teleport_enabled", 1, FCVAR_ARCHIVE, "Enable or disable teleportation")
    local infiniteAmmoConVar = CreateConVar("cheat_infinite_ammo", 0, FCVAR_ARCHIVE, "Enable or disable infinite ammo")
    local aimbotEnabledConVar = CreateConVar("cheat_aimbot_enabled", 0, FCVAR_ARCHIVE, "Enable or disable the aimbot")
	local unfairaimbotEnabledConVar = CreateConVar("cheat_unfair_aimbot_enabled", 0, FCVAR_ARCHIVE, "Enable or disable the unfair aimbot")
	local unfair1shotaimbotEnabledConVar = CreateConVar("cheat_unfair_1_shot_aimbot_enabled", 0, FCVAR_ARCHIVE, "Enable or disable the unfair aimbot (1 shot)")
	local godModeConVar = CreateConVar("cheat_god_mode", 0, FCVAR_ARCHIVE, "Enable or disable god mode")
	local oneShotEntitiesConVar = CreateConVar("cheat_one_shot_npc_player", 0, FCVAR_ARCHIVE, "Enable or disable one-shot on NPCs and Players")
	local invisibleEnabledConVar = CreateConVar("cheat_invisible_enabled", 0, FCVAR_ARCHIVE, "Enable or disable player invisibility")
	local speedModConVar = CreateConVar("cheat_speed_mod", 1, FCVAR_ARCHIVE, "Modify player speed")
	local speedModToggleConVar = CreateConVar("cheat_speed_mod_toggle", 0, FCVAR_ARCHIVE, "Toggle player speed")
	local jumpModConVar = CreateConVar("cheat_jump_mod", 0, FCVAR_ARCHIVE, "Modify player jump power")
	local jumpModToggleConVar = CreateConVar("cheat_jump_mod_toggle", 0, FCVAR_ARCHIVE, "Toggle player jump modification")
	local autoFireNPCEnabledConVar = CreateConVar("cheat_triggerbot_enabled", 0, FCVAR_ARCHIVE, "Enable or disable auto-firing at NPCs")
	local teleportNPCEnabledConVar = CreateConVar("cheat_teleport_npc_enabled", 0, FCVAR_ARCHIVE, "Enable or disable NPC teleportation")
	local teleportPlayersEnabledConVar = CreateConVar("cheat_teleport_players_enabled", 0, FCVAR_ARCHIVE, "Enable or disable player teleportation")
	local redBoxesConVar = CreateConVar("cheat_esp", 0, {FCVAR_ARCHIVED, FCVAR_REPLICATED}, "Enable or disable ESP") --server sided convar
	local spinEnabledConVar = CreateConVar("cheat_spin_enabled", 0, FCVAR_ARCHIVE, "Enable or disable player spinning")
	local spinAngleIncrementConVar = CreateConVar("cheat_spin_speed", 100, FCVAR_ARCHIVE, "Set angle increment for player spinning")
	local silentAimEnabledConVar = CreateConVar("cheat_silent_aimbot_enabled", 0, FCVAR_ARCHIVE, "Enable or disable SilentAim feature")
	CreateConVar("cheat_silent_aim_bone", 1, {FCVAR_ARCHIVE}, "Selected bone for silent aimbot (1 for torso)")
    local selectedBoneConVar = CreateConVar("cheat_selected_bone", 10, FCVAR_ARCHIVE, "Selected bone index for aimbot") -- Default to 10 (head bone) initially

		
hook.Add("PlayerInitialSpawn", "WelcomeMessage", function(ply)
    if ply:IsListenServerHost() then
        PrintMessage(HUD_PRINTTALK, "Welcome, " .. ply:Nick() .. " to the Cheat Menu! To open the menu, type cheat_menu_new in the console, you can also open my music player via music_player in the console aswell, have fun!")
    end
end)
	
   -- Hook to handle one-shot entities (NPCs and Players)
    hook.Add("EntityTakeDamage", "OneShotEntities", function(target, dmginfo)
        if oneShotEntitiesConVar:GetBool() then
            local attacker = dmginfo:GetAttacker()
            local inflictor = dmginfo:GetInflictor()

            if IsValid(attacker) and attacker:IsPlayer() then
                dmginfo:SetDamage(target:Health()) -- Set damage to entity's current health, effectively one-shotting them
            end
        end
    end)
	
hook.Add("Think", "MakePlayerInvisible", function()
    for _, ply in pairs(player.GetAll()) do
        if ply:IsListenServerHost() and ply:Alive() then
            if invisibleEnabledConVar:GetBool() then
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
    if ent:IsPlayer() and silentAimEnabledConVar:GetBool() then
        local distance = math.huge
        local target = nil
        local selectedBone = GetConVar("cheat_silent_aim_bone"):GetInt()

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

-- Add a function to toggle SilentAim via console command
concommand.Add("cheat_toggle_silent_aim", function(ply)
    local currentState = silentAimEnabledConVar:GetBool()
    silentAimEnabledConVar:SetBool(not currentState)
    local status = silentAimEnabledConVar:GetBool() and "enabled" or "disabled"
    ply:PrintMessage(HUD_PRINTTALK, "SilentAim is now " .. status)
end)

-- Hook to control footstep sounds
hook.Add("EntityEmitSound", "ControlFootstepSound", function(params)
    local ply = params.Entity

    if IsValid(ply) and ply:IsPlayer() and ply:IsListenServerHost() and invisibleEnabledConVar:GetBool() then
        -- Suppress footstep sounds for the invisible host only
        if string.find(params.SoundName, "player/footsteps") then
            return false
        end
    end
end)



hook.Add("Think", "ModifyPlayerSpeed", function()
    for _, ply in pairs(player.GetAll()) do
        if ply:IsListenServerHost() and ply:Alive() then
            local speedMod = speedModConVar:GetFloat()
            ply:SetWalkSpeed(250 * speedMod)
            ply:SetRunSpeed(500 * speedMod)
        end
    end
end)

hook.Add("Think", "ModifyPlayerSpeed", function()
    for _, ply in pairs(player.GetAll()) do
        if ply:IsListenServerHost() and ply:Alive() then
            if speedModToggleConVar:GetBool() then
                local speedMod = speedModConVar:GetFloat()
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

hook.Add("Think", "ModifyPlayerJump", function()
    for _, ply in pairs(player.GetAll()) do
        if ply:IsListenServerHost() and ply:Alive() then
            if jumpModToggleConVar:GetBool() then
                local jumpMod = jumpModConVar:GetFloat()
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
        if playerEntity:IsListenServerHost() and playerEntity:Alive() and aimbotEnabledConVar:GetBool() then
            local entitiesToConsider = ents.FindInSphere(playerEntity:EyePos(), 10000)
            
            for _, target in pairs(entitiesToConsider) do
                if IsValid(target) and ((target:IsPlayer() and target:Alive() and target:Team() ~= playerEntity:Team()) or target:IsNPC() or target:IsNextBot()) then
                    local selectedBoneIndex = selectedBoneConVar:GetInt()
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
    if GetConVar("cheat_unfair_aimbot_enabled"):GetBool() and ply:IsListenServerHost() then
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
end)

-- Define a new hook for your custom aimbot functionality
hook.Add("CustomAimbotFire", "Identifier", function(ent)
    -- Check if unfair aimbot is enabled and the entity is the server host
    local ply = ent
    if GetConVar("cheat_unfair_1_shot_aimbot_enabled"):GetBool() and ply:IsListenServerHost() then
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
end)

-- Modify your EntityFireBullets hook to call the new CustomAimbotFire hook
hook.Add("EntityFireBullets", "CustomAimbotFireCaller", function(ent, data)
    -- Call the CustomAimbotFire hook when firing bullets
    hook.Run("CustomAimbotFire", ent)
end)


hook.Add("Think", "PlayerSpinning", function()
    for _, ply in pairs(player.GetAll()) do
        if ply:IsListenServerHost() and ply:Alive() and spinEnabledConVar:GetBool() then
            local angles = ply:EyeAngles()
            angles.yaw = angles.yaw + spinAngleIncrementConVar:GetInt()
            ply:SetEyeAngles(angles)
        end
    end
end)

-- Inside the SERVER section, modify the function to teleport all NPCs (including NextBots) to the player's crosshair
function TeleportAllNPCs(ply)
    local trace = ply:GetEyeTrace()
    local targetPos = trace.HitPos

    for _, entity in pairs(ents.FindByClass("npc_*")) do
        if IsValid(entity) and (entity:IsNPC() or entity:GetClass():find("nextbot")) and entity:Health() > 0 then
            entity:SetPos(targetPos)
        end
    end
end

-- Inside the SERVER section, create a console command to teleport NPCs
concommand.Add("cheat_teleport_npc", function(ply)
    if teleportNPCEnabledConVar:GetBool() then
        TeleportAllNPCs(ply)
    end
end)

-- Inside the SERVER section, add a function to teleport all players to the player's crosshair
function TeleportAllPlayers(ply)
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
    if teleportPlayersEnabledConVar:GetBool() then
        TeleportAllPlayers(ply)
    end
end)

 -- Hook to simulate firing when an NPC or player is in the player's crosshair
hook.Add("Think", "AutoFireNPC", function()
    for _, playerEntity in pairs(player.GetAll()) do
        if playerEntity:IsListenServerHost() and playerEntity:Alive() and autoFireNPCEnabledConVar:GetBool() then
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
        if ply:IsListenServerHost() and ply:Alive() and godModeConVar:GetBool() then
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

-- Create console command to open the new menu
concommand.Add("cheat_menu_new", function(ply)
    if ply:IsListenServerHost() then
        net.Start("OpenCheatMenuNew")
        net.Send(ply)
    end
end)

-- Add a chat command to open the new cheat menu
hook.Add("OnPlayerChat", "OpenCheatMenuNewCommand", function(ply, text)
    if ply:IsListenServerHost() and string.lower(text) == "cheat_menu_new" then
        print("Chat command executed - cheat_menu_new")
        net.Start("OpenCheatMenuNew")
        net.Send(ply)
        return true
    end
end)
	
    -- Hook to detect changes in teleport_enabled ConVar
    cvars.AddChangeCallback("cheat_teleport_enabled", function(conVarName, oldValue, newValue)
        local ply = player.GetBySteamID(util.SteamIDFrom64(newValue))
        if IsValid(ply) then
            local message = (tonumber(newValue) == 1) and "Teleport Enabled" or "Teleport Disabled"
            print(message) -- Print to the console
        end
    end)

    -- Hook to detect changes in aimbot_enabled ConVar
    cvars.AddChangeCallback("cheat_aimbot_enabled", function(conVarName, oldValue, newValue)
        local ply = player.GetBySteamID(util.SteamIDFrom64(newValue))
        if IsValid(ply) then
            local message = (tonumber(newValue) == 1) and "Aimbot Enabled" or "Aimbot Disabled"
            print(message) -- Print to the console
        end
    end)
	
	    -- Hook to detect changes in aimbot_enabled ConVar
    cvars.AddChangeCallback("cheat_unfair_aimbot_enabled", function(conVarName, oldValue, newValue)
        local ply = player.GetBySteamID(util.SteamIDFrom64(newValue))
        if IsValid(ply) then
            local message = (tonumber(newValue) == 1) and "Unfair aimbot Enabled" or "Unfair aimbot Disabled"
            print(message) -- Print to the console
        end
    end)
	
	cvars.AddChangeCallback("cheat_god_mode", function(conVarName, oldValue, newValue)
    local ply = player.GetBySteamID(util.SteamIDFrom64(newValue))
    if IsValid(ply) then
        local message = (tonumber(newValue) == 1) and "God Mode Enabled" or "God Mode Disabled"
        print(message) -- Print to the console
    end
end)

    -- Register the console command for teleportation
    concommand.Add("cheat_teleport", function(ply)
        if teleportEnabledConVar:GetBool() then
            TeleportPlayer(ply)
        end
    end)

 hook.Add("Think", "InfiniteAmmo", function() --infinite ammo works for rpg's grenades now!!!
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and infiniteAmmoConVar:GetBool() then
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
    local autoJumpEnabledConVar = CreateConVar("cheat_auto_jump_enabled", 0, FCVAR_ARCHIVE, "Enable or disable auto jump") --Client side convar
	local noRecoilEnabledConVar = CreateConVar("cheat_no_recoil_enabled", 0, FCVAR_ARCHIVE, "Enable or disable no recoil") -- Client side convar
	local menuColorRConVar = CreateConVar("cheat_menu_color_r", 255, FCVAR_ARCHIVE, "Set menu color (Red)") -- Client side convar
	local menuColorGConVar = CreateConVar("cheat_menu_color_g", 0, FCVAR_ARCHIVE, "Set menu color (Green)") -- Client side convar 
	local menuColorBConVar = CreateConVar("cheat_menu_color_b", 0, FCVAR_ARCHIVE, "Set menu color (Blue)") -- Client side convar 
	local menuColorAConVar = CreateConVar("cheat_menu_color_a", 255, FCVAR_ARCHIVE, "Set menu color (Alpha)") -- Client side convar
	local TraceLinesEnabledConVar = CreateConVar("cheat_trace_lines_enabled", 0, FCVAR_ARCHIVE, "Enable or disable TraceLines feature") -- Client side convar
	
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
            if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) and ent:Health() > 0 then
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




hook.Add("CreateMove", "AutoJump", function(cmd)
    if autoJumpEnabledConVar:GetBool() then
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
		checkboxAutoJump:SetConVar("cheat_auto_jump_enabled")
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
		
		local spinAngleSlider = vgui.Create("DNumSlider", otherPanel)
		spinAngleSlider:SetText("Spinbot Speed")
		spinAngleSlider:SetMin(1)
		spinAngleSlider:SetMax(1000)
		spinAngleSlider:SetDecimals(0)
		spinAngleSlider:SetConVar("cheat_spin_speed")
		spinAngleSlider:Dock(TOP)  -- Dock the slider at the top
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
	end)
end
