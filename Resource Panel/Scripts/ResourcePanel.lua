--- Configuration table.
-- NOT saved onSave. 
CONSTANTS = {
  resourceScriptingZoneGUID = "06b581", -- string: GIUD of a resource scripting zone.
  bgColor = "#000000", -- string: Panel background color.
  textColor = "#ffffff", -- string: Text color.
  fontSize = 200, -- number: Font size.
  buttonColor = "#ffffff", -- string: Button background color.
  buttonTextColor = "#000000", -- string: Button text color. 
  buttonFontSize = 70, -- number: Button font size.
  readyResourcesTextColor = "#1382AB", -- string: Available resource count text color.
  zeroResourcesTextColor = "#A01D1D", -- string: Zero resources text color.
}

--- Variables table.
-- Do not modify!
-- Saved on Save and load on Load.
VARIABLES = {
  resourceCards = {}, -- tab: Table of resource cards.
  readyCards = 0, -- number: Number of ready resources.
}

--- Saves variables table.
-- TTS API called on save/autosave for every object.
-- Encodes parameter table to JSON and returns it as saved data.
--@treturn tab saved_data JSON encoded table.
function onSave()
  if #VARIABLES.resourceCards == 0 then 
    saved_data = "" 
    return saved_data
  else      
    local cardGUIDTable = {}
    -- Create resource table with GUID list from object list.
    for i=1, #VARIABLES.resourceCards do
      local resource = {
        card = VARIABLES.resourceCards[i].card.getGUID(),
        state = VARIABLES.resourceCards[i].state,
      } 
      table.insert(cardGUIDTable, resource)
    end
    local data_to_save = { 
      resources = cardGUIDTable,
    }
    saved_data = JSON.encode(data_to_save)
    return saved_data
  end
end

--- Loads saved data.
-- TTS API Called when an object is loaded or spawned.
-- Loads variables table from JSON encoded saved_data if it exists,
-- sets custom assets, and resets resources.
-- @tparam tab saved_data JSON encoded table.
-- @see setResources
function onLoad(saved_data)
  if saved_data ~= "" then
    -- Load Data from save file.
    local loaded_data = JSON.decode(saved_data)
    local cardGUIDTable = loaded_data.resources
    VARIABLES.resourceCards = {}
    -- Create resource table with object list from GUID list.
    for i = 1, #cardGUIDTable do 
      local resource = {
        card = getObjectFromGUID(cardGUIDTable[i].card),
        state = cardGUIDTable[i].state,
      } 
      table.insert(VARIABLES.resourceCards, resource)
    end
  else
    VARIABLES.resourceCards = {}
  end
  -- Sets image Assets.
  self.UI.setCustomAssets({
    {
      name = "STU_exhaust_arrow",
      url = "http://cloud-3.steamusercontent.com/ugc/2495632040039052344/9C5EC52C650FCB4CB24B7D8BDD5551247F6FD186/"
    },
    {
      name = "STU_ready_arrow",
      url = "http://cloud-3.steamusercontent.com/ugc/2495632040039054817/604AD7BE9AEAB8C0D39C77BEFFD8FC0179622FBC/"
    }
  })

  setResources()
end

--- Arranges cards in the resource area. 
function setResources()

  local cardCount = #VARIABLES.resourceCards
  VARIABLES.readyCards = 0
  -- Variable for sorted cards.
  local resources = {}

  if cardCount ~= 0 then
    local forward = Vector(self.getTransformForward())
    local right = Vector(self.getTransformRight())

    -- Card sorting. Ready cards on the left exhausted cards on the right.
    local readyResources = {}
    
    for i=1,#VARIABLES.resourceCards, 1 do
      local cardForward = Vector(VARIABLES.resourceCards[i].card.getTransformForward())*Vector(1,1,-1)
      if VARIABLES.resourceCards[i].state == "ready" then
        table.insert(readyResources,1,VARIABLES.resourceCards[i])
        VARIABLES.readyCards = VARIABLES.readyCards + 1
      elseif VARIABLES.resourceCards[i].state == "exhausted" then
        table.insert(resources, VARIABLES.resourceCards[i])
      end
    end
    for i=1,#readyResources, 1 do
      table.insert(resources,1,readyResources[i])
    end
    VARIABLES.resourceCards = resources

    -- Starting position of the spread is on the bottom right.
    local cardSpread = 0.77
    local startOffset = right * (cardSpread*(cardCount-1))
    local cardSize = resources[1].card.getBoundsNormalized().size 
    local Z = self.getPosition().z
    local Y = self.getPosition().y-self.getBoundsNormalized().size.y/2 + 0.02
    local X = self.getPosition().x+self.getBoundsNormalized().size.x/2 + 0.5 + startOffset.x + cardSize.z/2
    
    self.clearButtons()
    -- loop table in reverse. From right to left, and bottom to top.
    for i=#resources, 1, -1 do 
      resources[i].card.lock()      
      if resources[i].state == "ready" then        
        resources[i].card.setPositionSmooth({X-((cardSize.z-cardSize.x)/2),Y,Z})
      elseif resources[i].state == "exhausted"  then
        resources[i].card.setPositionSmooth({X,Y,Z-((cardSize.z-cardSize.x)/2)})
      end
      Y = Y + cardSize.y
      offset = right * cardSpread
      X = X - offset.x
      Z = Z
    end
  end

  createUI()
  -- Waits for cards to start and stop moving, and then add buttons.
  if cardCount ~= 0 then
    Wait.time(function() 
      Wait.condition(
        function() 
          addCardButtons()  
        end,
        function()
          local condition = true
          for i=1, #resources, 1 do
            condition = condition and resources[i].card.resting
          end
          return condition
        end,
        5, -- timeout
        function() -- Executed if our timeout is reached
          broadcastToAll("Something went wrong!", Color.red)
        end
      )
    end, 1)
  end
end

--- Clears all card buttons.
function clearCardButtons()
  local oldUI = self.UI.getXmlTable()
  local newUI = {}
  -- Gets only the UI panel, and sets it as new UI.
  table.insert(newUI, oldUI[1])
  self.UI.setXmlTable(newUI)
end

--- Adds buttons for exhausting and readying the cards.
function addCardButtons()
  local scale = self.getScale()
  local thickness = self.getCustomObject().thickness
  local resources = VARIABLES.resourceCards
  local oldUI = self.UI.getXmlTable()
  local newUI = {}
  -- Gets only the UI panel from the old UI.
  table.insert(newUI, oldUI[1])

  for i=1, #resources, 1 do

    -- Sets button position to top right corner of the card.
    local cardPosition = resources[i].card.getPosition()
    local cardSize = resources[i].card.getBounds().size
    local buttonPosition = Vector(cardPosition) + Vector(cardSize.x/2,cardSize.y/2,cardSize.z/2)
    local offset = Vector(-50,-1,-50)
    local localButtonPosition = Vector(self.positionToLocal(buttonPosition)):scale(100,-100,100) + offset
    
    local clickFunction = "onReadyButtonClick"
    local image = "STU_ready_arrow"
    if resources[i].state == "ready" then
      clickFunction = "onExhaustButtonClick"
      image = "STU_exhaust_arrow"
    end

    local buttonUI = {
      tag = "Button",
      attributes = {
        id = self.getGUID() .. "CardButton" .. i,
        text = "",
        onClick = clickFunction,
        fontSize = 50,
        fontColor = CONSTANTS.buttonTextColor,
        color = CONSTANTS.buttonColor,
        fontStyle = "bold",
        scale = scale.x .. " " .. scale.z .. " 1",
        position = localButtonPosition.x .. " " .. localButtonPosition.z .. " " .. localButtonPosition.y,
        width = 90,
        height = 90, 
        image = image,
      },
    }
    table.insert(newUI, buttonUI)
  end
  self.UI.setXmlTable(newUI)
end

-- Event called after user clicks ready button.
-- @tparam string id Button ID.
-- @see addCardButtons
function onReadyButtonClick(_, _, id)

  local i = id:match(self.getGUID().."CardButton(%d+)")
  
  if i ~= nil then
    i = tonumber(i)
    VARIABLES.resourceCards[i].card.setRotationSmooth({0,self.getRotation().y+180,180})
    VARIABLES.resourceCards[i].state = "ready"
    setResources()
  end
end

-- Event called after user clicks exhaust button.
-- @tparam string id Button ID.
-- @see addCardButtons
function onExhaustButtonClick(_, _, id)

  local i = id:match(self.getGUID().."CardButton(%d+)")
  
  if i ~= nil then
    i = tonumber(i)
    -- Loops for all previous cards to exhaust more than one.
    for n=1, i, 1 do
      VARIABLES.resourceCards[n].card.setRotationSmooth({0,self.getRotation().y+270,180})
      VARIABLES.resourceCards[n].state = "exhausted"
    end
      setResources()
  end
end

--- Readies all Card.
-- Called externally from the Ready Panel.
function readyAllCards()
  -- Check if any card is exhausted, to save performance and IU recreation.
  local isAnyExhausted = false
  for i=1, #VARIABLES.resourceCards, 1 do
    if VARIABLES.resourceCards[i].state == "exhausted" then
      isAnyExhausted = true
      break
    end
  end
  if isAnyExhausted then 
    for i=1, #VARIABLES.resourceCards, 1 do
      VARIABLES.resourceCards[i].card.setRotationSmooth({0,self.getRotation().y+180,180})
      VARIABLES.resourceCards[i].state = "ready"
    end
    setResources()
  end
end

--- Creates UI on the panel.
function createUI()
  local scale = self.getScale()  
  local thickness = self.getCustomObject().thickness  
  local readyResourcesTextColor = CONSTANTS.readyResourcesTextColor
  if VARIABLES.readyCards == 0 then
    readyResourcesTextColor = CONSTANTS.zeroResourcesTextColor
  end
  -- Set table for xml UI panel
  local ui = {
    {
      tag = "Panel",
      attributes = {
        id = "MainPanel" .. self.getGUID(),
        position = "0 0 " .. -50*thickness-0.5,
        rotation = "0 0 0",
        scale = "0.5 0.5 1",
        color = "#00000000",
        width = 700,
        height = 700,
        allowDragging = "false",
      }, 
      children = {
        {
          tag = "Panel",
          attributes = {
            rotation = "0 0 0",
            color = CONSTANTS.bgColor,
            width = 700,
            height = 520,
            allowDragging = "false",
            rectAlignment = "UpperCenter",
            childAlignment = "UpperLeft",
          }, 
          children = {
            {
              tag = "VerticalLayout",
              attributes = {
                childForceExpandHeight = "false",
                childAlignment = "MiddleCenter",
              },
              children = {
                {
                  tag = "HorizontalLayout",
                  attributes = {
                    childForceExpandHeight = "false",
                    childForceExpandWidth = "false",
                    childAlignment = "MiddleCenter",
                  },
                  children = {
                    {
                      tag = "Text",
                      attributes = {
                        color = readyResourcesTextColor,
                        fontSize = math.floor(CONSTANTS.fontSize),
                        fontStyle = "bold",
                        text = VARIABLES.readyCards,
                      },
                    },
                    {
                      tag = "Text",
                      attributes = {
                        color = CONSTANTS.textColor,
                        fontSize = math.floor(CONSTANTS.fontSize),
                        fontStyle = "bold",
                        text = " / " .. #VARIABLES.resourceCards,
                      },
                    },
                  },
                },
              },
            },
          },     
        },
        {
          tag = "Panel",
          attributes = {
            rotation = "0 0 0",
            color = CONSTANTS.bgColor,
            width = 700,
            height = 180,
            allowDragging = "false",
            childAlignment = "LowerRight",
            childForceExpandHeight = "false",
            childForceExpandWidth = "false",
            rectAlignment = "LowerCenter",
          }, 
          children = {
            {
              tag = "Button",
              attributes = {
                text = "UNLOCK",
                onClick = "onUnlockAllCards",
                fontSize = math.floor(CONSTANTS.buttonFontSize),
                fontColor = CONSTANTS.buttonTextColor,
                color = CONSTANTS.buttonColor,
                fontStyle = "bold",
                rectAlignment = "middleRight",
                height = 100,
                width = 350,
              },
            },
          },
        },
      },
    },
  }

  self.UI.setXmlTable(ui)
end

-- Event called after user clicks unlock button.
-- @see createUI
function onUnlockAllCards()
  clearCardButtons()
  for i=1, #VARIABLES.resourceCards, 1 do
    VARIABLES.resourceCards[i].card.setRotationSmooth({0,self.getRotation().y+180,180})
    local position = Vector(0,0,0)
    local cardSize = VARIABLES.resourceCards[i].card.getBoundsNormalized().size 
    position.x = self.getPosition().x + self.getBoundsNormalized().size.x/2 + 0.5 + cardSize.z/2
    position.y = VARIABLES.resourceCards[i].card.getPosition().y
    position.z = self.getPosition().z
    VARIABLES.resourceCards[i].card.setPositionSmooth(position)
    VARIABLES.resourceCards[i].state = "unlocked"
  end
  -- Waits until all the cards stop moving before unlocking them.
  Wait.condition(
    function()
      for i=1, #VARIABLES.resourceCards, 1 do
        VARIABLES.resourceCards[i].card.unlock()
      end 
      VARIABLES.resourceCards = {}
      setResources()
    end,
    function()
      local condition = true
      for i=1, #VARIABLES.resourceCards, 1 do
        condition = condition and VARIABLES.resourceCards[i].card.resting
      end
      return condition
    end,
    5,
    function()
      broadcastToAll("Something went wrong!", Color.red)
    end
  )

end

--- Called when an object enters a zone.
-- @tparam obj zone Zone that was entered.
-- @tparam obj object Object that entered the zone.
function onObjectEnterZone(zone, object)
  -- Checks if the card is in "unlocked" state.
  local unlockedCard = false
  for i=1, #VARIABLES.resourceCards, 1 do
    if object == VARIABLES.resourceCards[i].card and VARIABLES.resourceCards[i].state == "unlocked" then
      unlockedCard = true
      break
    end
  end
  if zone.getGUID() == CONSTANTS.resourceScriptingZoneGUID  and not unlockedCard then
    if object.hasTag("Card") and object.type == "Card" then
      -- Wait a second to check if card stayed in the zone or just passing.
      Wait.time(
        function() 
          local zoneOccupants = zone.getObjects()
          local stayed = false
          for k,v in pairs(zoneOccupants) do
            if v == object then 
              stayed = true 
              break
            end
          end
          if stayed then
            object.setRotationSmooth({0,self.getRotation().y+270,180}) 
            local resource = {
              card = object,
              state = "exhausted",
            } 
            table.insert(VARIABLES.resourceCards, resource)
            -- Wait until the card stops moving before resetting the resources. 
            Wait.condition(
              function()                     
                setResources()
              end,
              function()
                return object.resting
              end,
              5, -- timeout
              function() -- Executed if our timeout is reached
                broadcastToAll("Something went wrong!", Color.red)
              end
            ) 
          end
        end
      ,1)  
    end    
  end
end

--- Called when an object leaves a zone.
-- @tparam obj zone Zone that was leaved.
-- @tparam obj object Object that leaved the zone.
function onObjectLeaveZone(zone, object)
  local unlockedCard = false
  if zone.getGUID() == CONSTANTS.resourceScriptingZoneGUID then
    if object.hasTag("Card") and object.type == "Card" then
      for i=1, #VARIABLES.resourceCards, 1 do
        
        if VARIABLES.resourceCards[i].card == object then
          -- Checks if the card is in "unlocked" state.
          if VARIABLES.resourceCards[i].state == "unlocked" then
            unlockedCard = true
          end
          table.remove(VARIABLES.resourceCards, i)
          break
        end
      end
    end
    -- Resets resources only for a "proper" card.
    if not unlockedCard then
      setResources()
    end
  end
end