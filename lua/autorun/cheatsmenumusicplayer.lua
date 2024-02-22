if SERVER then
    AddCSLuaFile()
    return
end

-- Client-side code
local function OpenMusicPlayer()
    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 400)
    frame:SetTitle("Music Player")
    frame:Center()

    frame:SetDraggable(true)
    frame:SizeToContents()
    frame:SetSizable(true)
    frame:SetMinWidth(200)
    frame:SetMinHeight(150)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(255, 0, 0, 255))
    end

    frame:MakePopup()

    local list = vgui.Create("DListView", frame)
    list:Dock(FILL)
    list:AddColumn("Song")

    local folderInput = vgui.Create("DTextEntry", frame)
    folderInput:Dock(TOP)
    folderInput:SetPlaceholderText("Enter folder name")

    local addButton = vgui.Create("DButton", frame)
    addButton:Dock(TOP)
    addButton:SetText("Go To Folder")

    local backButton = vgui.Create("DButton", frame)
    backButton:Dock(BOTTOM)
    backButton:SetText("Back")

    -- New button to go back to the previous folder
    local goBackButton = vgui.Create("DButton", frame)
    goBackButton:Dock(BOTTOM)
    goBackButton:SetText("Go Back to the folder you were in")

    local previousFolders = {}  -- Table to store previous folders

    local function UpdateList(folder)
        list:Clear()

        local files, _ = file.Find("sound/" .. folder .. "/*", "GAME")

        for _, entry in ipairs(files) do
            list:AddLine(entry)
        end
    end

    UpdateList("")

    addButton.DoClick = function()
        local folderName = folderInput:GetValue()
        if folderName ~= "" then
            table.insert(previousFolders, folderName)  -- Store the current folder in the table
            UpdateList(folderName)
        end
    end

    backButton.DoClick = function()
        local currentFolder = folderInput:GetValue()
        local segments = {}
        for segment in currentFolder:gmatch("([^/]+)") do
            table.insert(segments, segment)
        end
        table.remove(segments)
        local previousFolder = table.concat(segments, "/")
        folderInput:SetText(previousFolder)
        UpdateList(previousFolder)
    end

    goBackButton.DoClick = function()
        -- Go back to the previous folder from the stored table
        local previousFolder = table.remove(previousFolders)
        if previousFolder then
            folderInput:SetText(previousFolder)
            UpdateList(previousFolder)
        end
    end

    local playButton = vgui.Create("DButton", frame)
    playButton:Dock(BOTTOM)
    playButton:SetText("Play Selected Song")

	 playButton.DoClick = function()
		local selectedLine = list:GetSelectedLine()
		if selectedLine then
			local selectedEntry = list:GetLine(selectedLine):GetValue(1)
			local selectedFolder = folderInput:GetValue()
			local path = "sound/" .. selectedFolder .. "/" .. selectedEntry --Fixed!, now you can play music from any folder!

			sound.PlayFile(path, "noplay", function(station, errorID, errorName)
				if IsValid(station) then
					station:Play()
				else
					print("Error playing music:", errorID, errorName)
				end
			end)
		end
	end

    local stopButton = vgui.Create("DButton", frame)
    stopButton:Dock(BOTTOM)
    stopButton:SetText("Stop Music")

    stopButton.DoClick = function()
        RunConsoleCommand("stopsound")
    end
end

concommand.Add("music_player", OpenMusicPlayer)

hook.Add("OnPlayerChat", "OpenMusicPlayerCommand", function(ply, text)
    if string.lower(text) == "music_player" then
        OpenMusicPlayer()
        return true
    end
end)
