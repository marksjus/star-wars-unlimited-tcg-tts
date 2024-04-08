--- Configuration table.
-- NOT saved onSave. 
CONSTANTS = {
  redLeaderScriptingZoneGIUD = "e408b6",
  redHandZoneGIUD = "99b44d",
  blueLeaderScriptingZoneGIUD = "07462e",
  blueHandZoneGIUD = "e59bda",
  bgColor = "#000000",
  buttonColor = "#ffffff",
  textFontColor = "#ffffff", -- string: Text color.
  buttonFontColor = "#000000", -- string: Text color.
  fontSize = 30, -- number: Font size.
}

--- Variables table.
-- Saved onSave and load on Load.
VARIABLES = {
  peeking = false,
  revealing = false,
  player = "",
  blueDeckScriptingZoneGIUD = "",
  redDeckScriptingZoneGIUD = "",
  hiddenZoneGIUD = "",
  ownerCardGIUD = "",
  enemyCardGIUD = "",
  leaderName = "",
}

--- Loads saved data.
-- TTS API Called when an object is loaded or spawned.
-- Loads variables table from JSON encoded saved_data if it exists, and
-- resets panel.
-- @tparam tab saved_data JSON encoded table
-- @see onResetAll
function onLoad(saved_data)
  if saved_data ~= "" then
    local loaded_data = JSON.decode(saved_data)
    VARIABLES = loaded_data
  end
  onResetAll()
end

--- Saves variables table.
-- TTS API called on save/autosave for every object.
-- Encodes parameter table to JSON and returns it as saved data.
--@treturn tab saved_data JSON encoded table
function onSave()
  local dataToSave = JSON.encode(VARIABLES)
  return dataToSave
end

--- Validated all zones from constants table.
-- @treturn bool Validation result.
function validateZones() 
  return getObjectFromGUID(CONSTANTS.redLeaderScriptingZoneGIUD) and
  getObjectFromGUID(CONSTANTS.redHandZoneGIUD) and
  getObjectFromGUID(CONSTANTS.blueLeaderScriptingZoneGIUD) and
  getObjectFromGUID(CONSTANTS.blueHandZoneGIUD)
end

--- Reset the panel.
function onResetAll()
  destroyDecksScriptingZone()
  destroyHiddenZone()
  setOwner()
  createUI()
end

--- Sets owner based on tile rotation.
function setOwner()
  local rotation = self.getRotation().y
  if rotation > 90 and rotation < 270 then
    VARIABLES.player = "blue"
  else
    VARIABLES.player = "red"
  end
end

--- Creates UI on the panel.
function createUI()
  local scale = self.getScale()  
  local thickness = self.getCustomObject().thickness
  local leaderSection = {}
  local zone = nil

  if validateZones() then
    -- Gets proper zone for the player.     
    if VARIABLES.player == "red" then
      zone = getObjectFromGUID(CONSTANTS.redLeaderScriptingZoneGIUD)
    else
      zone = getObjectFromGUID(CONSTANTS.blueLeaderScriptingZoneGIUD)
    end

    local occupants = zone.getObjects()
    
    -- Gets leader name from the zone.
    VARIABLES.leaderName = ""
    if #occupants ~= 0 then
      VARIABLES.leaderName=occupants[1].getName()
      if string.sub(VARIABLES.leaderName, 1, 1) == "*" then
        VARIABLES.leaderName = string.sub(VARIABLES.leaderName, 2, -1)
      end

      -- Sets leaderSection for the acquired leader.
      if VARIABLES.leaderName == "Grand Admiral Thrawn" then
        setDecksScriptingZone()
        leaderSection = {
          tag = "VerticalLayout",
          attributes = {
            childForceExpandHeight = "false",
            padding = "0 0 10 0",
          },
          children = {
            {
              tag = "Button",
              attributes = {
                id = "PeekButton" .. self.getGUID(),
                text = "Peek",
                onClick = "onDeckPeek",
                fontSize = math.floor(CONSTANTS.fontSize),
                fontColor = CONSTANTS.buttonFontColor,
                color = CONSTANTS.buttonColor,
                fontStyle = "bold",
                minHeight = 60,
              },
            },
            {
              tag = "Button",
              attributes = {
                id = "RevealOwnerButton" .. self.getGUID(),
                text = "Reveal Yours",
                onClick = "onRevealOwner",
                fontSize = math.floor(CONSTANTS.fontSize),
                fontColor = CONSTANTS.buttonFontColor,
                color = CONSTANTS.buttonColor,
                fontStyle = "bold",
                minHeight = 60,
              },
            },
            {
              tag = "Button",
              attributes = {
                id = "RevealEnemyButton" .. self.getGUID(),
                text = "Reveal Enemy",
                onClick = "onRevealEnemy",
                fontSize = math.floor(CONSTANTS.fontSize),
                fontColor = CONSTANTS.buttonFontColor,
                color = CONSTANTS.buttonColor,
                fontStyle = "bold",
                minHeight = 60,
              },
            },
          },
        }
      else
        VARIABLES.leaderName = "No scripted actions for leader"
      end
    else
      VARIABLES.leaderName = "No leader"
    end
  else
    VARIABLES.leaderName = "Zones not found"
  end

  -- Set table for xml UI panel
  local ui = {
    {
      tag = "Panel",
      attributes = {
        id = "Panel" .. self.getGUID(),
        position = "0 " .. 90*scale.z .. " " .. -50*thickness-0.5,
        rotation = "0 0 0",
        scale =  "1 1 1",
        color = CONSTANTS.bgColor,
        width = 500*scale.x,
        height = 520*scale.z,
        allowDragging = "false",
        childAlignment = "UpperLeft",
        padding = 30,
      }, 
      children = {
        {
          tag = "VerticalLayout",
          attributes = {
            childForceExpandHeight = "false",
          },
          children = {
            {
              tag = "Text",
              attributes = {
                color = CONSTANTS.textFontColor,
                fontSize = math.floor(CONSTANTS.fontSize),
                fontStyle = "bold",
                text = VARIABLES.leaderName,
              },
            },
          },
        },
      },     
    },
    {
      tag = "Panel",
      attributes = {
        id = "resetPanel" .. self.getGUID(),
        position = "0 " .. -260*scale.z .. " " .. -50*thickness-0.5,
        rotation = "0 0 0",
        scale =  "1 1 1",
        color = CONSTANTS.bgColor,
        width = 500*scale.x,
        height = 180*scale.z,
        allowDragging = "false",
        childAlignment = "LowerLeft",
        padding = 30,
      }, 
      children = {
        {
          tag = "Button",
          attributes = {
            text = "RESET",
            onClick = "onResetAll",
            fontSize = math.floor(CONSTANTS.fontSize),
            fontColor = CONSTANTS.buttonFontColor,
            color = CONSTANTS.buttonColor,
            fontStyle = "bold",
            minHeight = 60,
          },
        },
      },
    }
  }

  table.insert(ui[1].children[1].children,leaderSection)
  self.UI.setXmlTable(ui)
end

--- Called when an object enters a zone.
-- @tparam obj zone Zone that was entered.
-- @tparam obj object Object that entered the zone.
function onObjectEnterZone(zone, object)
  if zone.getGUID() == CONSTANTS.redLeaderScriptingZoneGIUD and 
  VARIABLES.player == "red" then
    createUI()
  end

  if zone.getGUID() == CONSTANTS.blueLeaderScriptingZoneGIUD and 
  VARIABLES.player == "blue" then
    createUI()
  end
end

--- Sets Hidden zone.
-- Hidden zone is player hand zone, and is used for card peeking.
-- @treturn obj hiddenZone Created hand zone.
function setHiddenZone()
  local position = {}
  local handZone = nil
  local hiddenZone = nil
  -- Since apparently we can create new hand zone
  -- but can't set color for it we're stealing a copy 
  -- of existing one and positioning it accordingly.
  if VARIABLES.player == "red" then
    position = {12.00, 4.00, -8.31}
    handZone = getObjectFromGUID(CONSTANTS.redHandZoneGIUD)
  else
    position = {-11.94, 4.00, 3.00}
    handZone = getObjectFromGUID(CONSTANTS.blueHandZoneGIUD)
  end
  local scale = {5.11, 4.00, 3.59}

  hiddenZone = handZone.clone({})
  VARIABLES.hiddenZoneGIUD = hiddenZone.getGUID()
  hiddenZone.setScale(scale)
  hiddenZone.setPosition(position)
  return hiddenZone
end

--- Destroys Hidden zone.
function destroyHiddenZone()
  if VARIABLES.hiddenZoneGIUD ~= "" then
    destroyObject(getObjectFromGUID(VARIABLES.hiddenZoneGIUD))
    VARIABLES.hiddenZoneGIUD = ""
  end
end

--- Creates scripting zones in both deck areas.
-- Used for fetching the card drom the decks.
function setDecksScriptingZone()
  local positionRed = {10.73, 3.00, -11.79}
  local scaleRed = {2.06, 5.10, 2.80}

  local positionBlue = {-10.71, 3.00, 6.48}
  local scaleBlue = {2.14, 5.10, 2.75}

  spawnObject({
    type = "ScriptingTrigger",
    position = positionRed,
    scale = scaleRed,
    rotation = {0,0,0},
    sound = false,
    callback_function = function(spawned_object)
      VARIABLES.redDeckScriptingZoneGIUD = spawned_object.getGUID()
    end
  })

  spawnObject({
    type = "ScriptingTrigger",
    position = positionBlue,
    scale = scaleBlue,
    rotation = {0,0,0},
    sound = false,
    callback_function = function(spawned_object)
      VARIABLES.blueDeckScriptingZoneGIUD = spawned_object.getGUID()
    end
  })
end

--- Destroys scripting zones.
function destroyDecksScriptingZone()
  if VARIABLES.redDeckScriptingZoneGIUD ~= "" then
    destroyObject(getObjectFromGUID(VARIABLES.redDeckScriptingZoneGIUD))
    VARIABLES.redDeckScriptingZoneGIUD = ""
  end

  if VARIABLES.blueDeckScriptingZoneGIUD ~= "" then
    destroyObject(getObjectFromGUID(VARIABLES.blueDeckScriptingZoneGIUD))
    VARIABLES.blueDeckScriptingZoneGIUD = ""
  end
end

--- Gets deck zone of a specified player.
-- @tparam string player Allowed values: "owner" or "enemy".
-- @treturn obj Deck scripting zone.
function getDeckZone(player)
  if player == "owner" then
    if VARIABLES.player == "red" then
      return getObjectFromGUID(VARIABLES.redDeckScriptingZoneGIUD) 
    else
      return getObjectFromGUID(VARIABLES.blueDeckScriptingZoneGIUD) 
    end
  elseif player == "enemy" then
    if VARIABLES.player == "red" then
      return getObjectFromGUID(VARIABLES.blueDeckScriptingZoneGIUD) 
    else
      return getObjectFromGUID(VARIABLES.redDeckScriptingZoneGIUD) 
    end
  else
    return nil
  end
end

--- Fetches a card from a specified deck scripting zone.
-- @tparam string player Allowed values: "owner" or "enemy".
-- @treturn obj card Card from the top of the deck area.
function getCard(player)
  -- Gets all objects in the deck zone. 
  local zoneOccupants = getDeckZone(player).getObjects()
  if zoneOccupants == nil then
    return nil
  end

  for i=1, #zoneOccupants, 1 do
    -- Checks if we found a deck, and get top card from it.
    if zoneOccupants[i].type == "Deck" then
      local card = zoneOccupants[i].takeObject(
        {
          position = zoneOccupants[i].getPosition(),
        }
      )
      return card
    -- Checks if we found a single card instead.
    elseif zoneOccupants[i].type == "Card" and zoneOccupants[i].getName() ~= "" then
      return zoneOccupants[i]
    end
  end
  return nil
end

--- Gets Color of a specified player.
-- @tparam string player Allowed values: "owner" or "enemy".
-- @treturn Color Player color.
function getColor(player)
  if player == "owner" then
    if VARIABLES.player == "red" then
      return Color.red
    else
      return Color.blue
    end
  elseif player == "enemy" then
    if VARIABLES.player == "red" then
      return Color.blue
    else
      return Color.red
    end
  else
    return nil
  end
end

--- Procedure for peeking cards from the decs. 
-- Event called after user clicks "Peek" button.
-- @see createUI
function onDeckPeek()
  -- Checks if we're already peeking.
  if not VARIABLES.peeking then
    VARIABLES.peeking = true
    local hiddenZone = nil
  
    local ownerCard = getCard("owner")
    local enemyCard = getCard("enemy")
    -- Checks if we have any cards.
    if ownerCard  ~= nil or enemyCard ~= nil then
      -- Redraws button to indicate that the cards are moving.
      self.UI.setAttribute("PeekButton" .. self.getGUID(), "text", "Traveling...") 
      self.UI.setAttribute("PeekButton" .. self.getGUID(), "color", "red") 
      self.UI.setAttribute("PeekButton" .. self.getGUID(), "onClick", "")
      
      broadcastToAll(VARIABLES.leaderName .. " uses his action to peek cards", getColor("owner"))    
      hiddenZone = setHiddenZone()

      -- Moves cards to position.
      if ownerCard ~= nil then
        VARIABLES.ownerCardGIUD = ownerCard.getGUID()
        ownerCard.setPositionSmooth(hiddenZone.getPosition())
      end

      if enemyCard ~= nil then
        VARIABLES.enemyCardGIUD = enemyCard.getGUID()
        enemyCard.setPositionSmooth(hiddenZone.getPosition())
        Wait.time(function() 
          enemyCard.setRotationSmooth(Vector(enemyCard.getRotation())+Vector(0,180,0)) 
        end, 0.1)
      end
      -- Waits until the enemy card arrives to hidden zone before flipping.    
      Wait.condition(
        function()  
          ownerCard.flip()
          enemyCard.flip() 
          -- Redraws button to indicate that the cards can be returned.
          self.UI.setAttribute("PeekButton" .. self.getGUID(), "text", "RETURN") 
          self.UI.setAttribute("PeekButton" .. self.getGUID(), "color", "red")    
          self.UI.setAttribute("PeekButton" .. self.getGUID(), "onClick", "onDeckPeekReturn")
        end,
        function()
            local ownerCondition = false         
            if ownerCard ~= nil then
              ownerCondition = ownerCard.resting
            else
              ownerCondition = true
            end

            local enemyCondition = false
            if enemyCard ~= nil then
              enemyCondition = enemyCard.resting
            else
              enemyCondition = true
            end

            return ownerCondition and enemyCondition
        end,
        5, -- timeout
        function() -- Executed if our timeout is reached
          broadcastToAll("Something went wrong!", getColor("owner"))
        end
      )
    else
      VARIABLES.peeking = false
    end
  end
end

--- Procedure for returning cards after peeking. 
-- Event called after user clicks "RETURN" button.
-- @see createUI
function onDeckPeekReturn()
  local ownerZone = getDeckZone("owner")
  local enemyZone = getDeckZone("enemy")
  local ownerCard = getObjectFromGUID(VARIABLES.ownerCardGIUD)
  local enemyCard = getObjectFromGUID(VARIABLES.enemyCardGIUD)

  -- Checks if we have any cards. We should have at least one but just in case. 
  if ownerCard ~= nil or enemyCard ~= nil then
    broadcastToAll(VARIABLES.leaderName .. " uses his action to return cards", getColor("owner"))  
    -- Redraws button to indicate that the cards are moving.
    self.UI.setAttribute("PeekButton" .. self.getGUID(), "text", "Traveling...") 
    self.UI.setAttribute("PeekButton" .. self.getGUID(), "color", "red") 
    self.UI.setAttribute("PeekButton" .. self.getGUID(), "onClick", "")
       
    if ownerCard ~= nil then
      VARIABLES.ownerCardGIUD = ""
      ownerCard.flip()    
    end

    if enemyCard ~= nil then
      VARIABLES.enemyCardGIUD = ""
      enemyCard.flip()
    end
    -- Waits until the cards are flipped before moving.      
    Wait.time(function() 
      destroyHiddenZone()
      if ownerCard ~= nil then     
        ownerCard.setPositionSmooth(ownerZone.getPosition())
      end
      if enemyCard ~= nil then
        enemyCard.setRotationSmooth(Vector(enemyCard.getRotation())+Vector(0,180,0)) 
        enemyCard.setPositionSmooth(enemyZone.getPosition())
      end
      Wait.condition(
        function()   
          Wait.time(function()
            -- Redraws button to indicate that we can peek again.
            self.UI.setAttribute("PeekButton" .. self.getGUID(), "text", "Peek") 
            self.UI.setAttribute("PeekButton" .. self.getGUID(), "color", CONSTANTS.buttonColor)    
            self.UI.setAttribute("PeekButton" .. self.getGUID(), "onClick", "onDeckPeek")
            VARIABLES.peeking = false
          end, 1.5)
        end,
        function()
            local ownerCondition = false         
            if ownerCard ~= nil then
              ownerCondition = ownerCard.resting
            else
              ownerCondition = true
            end

            local enemyCondition = false
            if enemyCard ~= nil then
              enemyCondition = enemyCard.resting
            else
              enemyCondition = true
            end

            return ownerCondition and enemyCondition
        end,
        5, -- timeout
        function() -- Executed if our timeout is reached
          broadcastToAll("Something went wrong!", getColor("owner"))
        end
      )
    end, 1) 
  end
end

--- Procedure for revealing card from the top of owner deck. 
-- Event called after user clicks "Reveal Yours" button.
-- @see createUI
function onRevealOwner() 
  -- Checks if we're already revealing.
  if not VARIABLES.revealing then
    VARIABLES.revealing = true
    local card = getCard("owner")
    -- Check if we have a card.
    if card ~= nil then
      -- Redraws button to indicate that we revealing a card.
      self.UI.setAttribute("RevealOwnerButton" .. self.getGUID(), "text", "Revealing...") 
      self.UI.setAttribute("RevealOwnerButton" .. self.getGUID(), "color", "red")    
      self.UI.setAttribute("RevealOwnerButton" .. self.getGUID(), "onClick", "")
      -- we have to lock card, otherwise it will fall immediately after revealing.      
      card.setLock(true)
      card.setPositionSmooth(Vector(card.getPosition())+Vector(0,3,0))
      card.setRotationSmooth(Vector(card.getRotation()) + Vector(0,0,180))    
      
      broadcastToAll(VARIABLES.leaderName .. " uses his action to reveal a " .. card.getName(), getColor("owner"))
      
      Wait.time(function() 
        -- The card is locked so we can't flip it we setting rotation instead.
        card.setRotationSmooth(Vector(card.getRotation()) + Vector(0,0,180))   
        -- Unlock card an wait until it fell.
        card.setLock(false)
        Wait.time(function() 
          VARIABLES.revealing = false
          -- Redraws button to indicate that we can reveal a card again.
          self.UI.setAttribute("RevealOwnerButton" .. self.getGUID(), "text", "Reveal Yours") 
          self.UI.setAttribute("RevealOwnerButton" .. self.getGUID(), "color", CONSTANTS.buttonColor)    
          self.UI.setAttribute("RevealOwnerButton" .. self.getGUID(), "onClick", "onRevealOwner")
        end, 1.5)
      end, 2)
    else
      VARIABLES.revealing = false
    end
  end
end

--- Procedure for revealing card from the top of enemy deck. 
-- Event called after user clicks "Reveal Enemy" button.
-- @see createUI
function onRevealEnemy()
  -- Checks if we're already revealing.
  if not VARIABLES.revealing then
    VARIABLES.revealing = true
    local card = getCard("enemy")
    -- Check if we have a card.
    if card ~= nil then
      -- Redraws button to indicate that we revealing a card.
      self.UI.setAttribute("RevealEnemyButton" .. self.getGUID(), "text", "Revealing...") 
      self.UI.setAttribute("RevealEnemyButton" .. self.getGUID(), "color", "red")    
      self.UI.setAttribute("RevealEnemyButton" .. self.getGUID(), "onClick", "")
      -- we have to lock card, otherwise it will fall immediately after revealing.      
      card.setLock(true)
      card.setPositionSmooth(Vector(card.getPosition())+Vector(0,3,0))
      card.setRotationSmooth(Vector(card.getRotation()) + Vector(0,0,180))    
      
      broadcastToAll(VARIABLES.leaderName .. " uses his action to reveal a " .. card.getName(), getColor("owner"))
      
      Wait.time(function() 
        -- The card is locked so we can't flip it we setting rotation instead.
        card.setRotationSmooth(Vector(card.getRotation()) + Vector(0,0,180))   
        -- Unlock card an wait until it fell.
        card.setLock(false)
        Wait.time(function() 
          VARIABLES.revealing = false
          -- Redraws button to indicate that we can reveal a card again.
          self.UI.setAttribute("RevealEnemyButton" .. self.getGUID(), "text", "Reveal Enemy") 
          self.UI.setAttribute("RevealEnemyButton" .. self.getGUID(), "color", CONSTANTS.buttonColor)    
          self.UI.setAttribute("RevealEnemyButton" .. self.getGUID(), "onClick", "onRevealEnemy")
        end, 1.5)
      end, 2)
    else
      VARIABLES.revealing = false
    end
  end
end

