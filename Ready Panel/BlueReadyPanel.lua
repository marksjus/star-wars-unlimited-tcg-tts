function onload(save_state)
    self.createButton({ click_function = 'untap', label = 'READY', function_owner = self, position = {0, 0.18, 0}, rotation = {0, 0, 0}, width = 1000, height = 1000, font_size = 250})
    if self.getDescription() == '' then
        setDefaultState()
    end
end

function onSave()
    return self.getDescription()
end

function setDefaultState()
    self.setDescription(JSON.encode({zone = "GUID_here", flip = "yes"}))
end

function split(s, delimiter)
    result = {}
    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

function compareRotations(rot1, rot2)
    local tolerance = 0.01
    for i = 1, 3 do
        if math.abs(rot1[i] - rot2[i]) > tolerance then
            return false
        end
    end
    return true
end

function untap(clicked_object, player)
    if self.getDescription() == "" then
        setDefaultState()
        printToAll('Warning - invalid description. Restored default configuration.', {0.8, 0.5, 0})
    end

    local data = JSON.decode(self.getDescription())
    if data == nil then
        setDefaultState()
        data = JSON.decode(self.getDescription())
        printToAll('Warning - invalid description. Restored default configuration.', {0.8, 0.5, 0})
    end

    for _, zoneGUID in pairs(split(data.zone, ";")) do
        zone = getObjectFromGUID(zoneGUID)
        if zone ~= nil and zone.type == "Scripting" then
            for _, v in pairs(zone.getObjects()) do
                if v.type == "Card" then
                    local targetRotation
                    if data.flip == "no" then
                        targetRotation = {self.getRotation().x, self.getRotation().y, v.getRotation().z}
                    else
                        targetRotation = self.getRotation()
                    end

                    -- Check if the card needs to be rotated
                    if not compareRotations(v.getRotation(), targetRotation) then
                        -- Rotate the card
                        v.setRotationSmooth(targetRotation)
                    end
                end
            end
        else
            printToAll("I can't find zone from description - " .. zoneGUID, {0.8, 0.5, 0})
        end
    end

    -- Leader Zone
    local leaderZoneGUID = "07462e"  -- Replace _ with the actual GUID of the leader zone
    local leaderZone = getObjectFromGUID(leaderZoneGUID)

    if leaderZone ~= nil and leaderZone.tag == "Scripting" then
        local buttonRotation = {self.getRotation().x, self.getRotation().y, self.getRotation().z}
        local expectedLeaderRotation = {self.getRotation().x, self.getRotation().y + 270, self.getRotation().z}

        for _, card in pairs(leaderZone.getObjects()) do
            if card.tag == "Card" then
                local relativeRotation = {card.getRotation().x, card.getRotation().y - buttonRotation[2], card.getRotation().z}

                if not compareRotations(relativeRotation, expectedLeaderRotation) then
                    card.setRotationSmooth(expectedLeaderRotation)
                end
            end
        end
    else
        printToAll("Leader zone not found - " .. leaderZoneGUID, {0.8, 0.5, 0})
    end

    -- Resource Panel
    local resourcePanelGUID = "bcc2c1"  -- Replace _ with the actual GUID of the Resource panel
    local resourcePanel = getObjectFromGUID(resourcePanelGUID)
    if resourcePanel ~= nil then
        resourcePanel.call("readyAllCards")
    else
        printToAll("Resource Panel not found - " .. resourcePanelGUID, {0.8, 0.5, 0})
    end
end
