CONSTANTS = {
  resourceScriptingZoneGUID = "06b581",
  bgColor = "#000000", -- string: Panel background color.
  textColor = "#ffffff", -- string: Text color.
  fontSize = 200, -- number: Font size.
  buttonColor = "#ffffff", -- string: Button background color.
  buttonTextColor = "#000000", -- string: Button text color. 
  buttonFontSize = 70, -- number: Font size.
  readyResourcesTextColor = "#1382AB", -- string: Button text color.
  zeroResourcesTextColor = "#A01D1D", -- string: Button text color.
}

VARIABLES = {
  resourceCards = {},
  readyCards = 0,
  boardcount = 0,
}

--Runs whenever game is saved/autosaved
function onSave()
 --Begin State Managment of Saving VARIABLES.resourceCards Object list.
 --Create GUID list fomr Object List
  --  if #VARIABLES.resourceCards == 0 then saved_data = "" return saved_data
  --  else
  --      local objectGUIDlist_sv = {}
  --      for i = 1, #VARIABLES.resourceCards do table.insert(objectGUIDlist_sv, VARIABLES.resourceCards[i].getGUID()) end
  --      local data_to_save = { dc=objectGUIDlist_sv }
     -- Save Code
  --     saved_data = JSON.encode(data_to_save)
     --saved_data = "" --Remove -- at start + save to clear save data
  --     return saved_data
  --  end

end

--Runs when game is loaded
function onLoad(saved_data)
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
 --Loads the tracking for if the game has started yet
    --if saved_data ~= "" then
     -- Load Data from save file and add to tmp variable.
    --    local loaded_data = JSON.decode(saved_data)
    --    local objectGUIDlist_ld = loaded_data.dc
    --    VARIABLES.resourceCards = {}
        --load Data in tmp_Variable, take the GUIDs and turn them into objects and add to script variable.
    --    for i = 1, #objectGUIDlist_ld do table.insert(VARIABLES.resourceCards, getObjectFromGUID(objectGUIDlist_ld[i])) end
    --else
    --    VARIABLES.resourceCards = {}
    --end

    --makeButtons()
end

--- Arranges cards i the resource area. 
function setResources()

  local cardCount = #VARIABLES.resourceCards
  VARIABLES.readyCards = 0
  local resources = {}
  if cardCount ~= 0 then
    local forward = Vector(self.getTransformForward())
    local right = Vector(self.getTransformRight())

    -- Card sorting.
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

    -- Starting position of the spread is on the right.
    local cardSpread = 0.77
    local startOffset = right * (cardSpread*(cardCount-1))
    local cardSize = resources[1].card.getBoundsNormalized().size 
    local Z = self.getPosition().z
    local Y = self.getPosition().y-self.getBoundsNormalized().size.y/2 + 0.02 + cardSize.y * cardCount
    local X = self.getPosition().x+self.getBoundsNormalized().size.x/2 + 0.5 + startOffset.x + cardSize.z/2
    
    self.clearButtons()
    -- loop table in reverse. From right to left. 
    for i=#resources, 1, -1 do 
      resources[i].card.lock() 
      -- Horizontal cards are placed lower, and vertical cards are farther to the left.      
      if resources[i].state == "ready" then        
        resources[i].card.setPositionSmooth({X-((cardSize.z-cardSize.x)/2),Y,Z})
      elseif resources[i].state == "exhausted"  then
        resources[i].card.setPositionSmooth({X,Y,Z-((cardSize.z-cardSize.x)/2)})
      end
      Y = Y - cardSize.y
      offset = right * cardSpread
      X = X - offset.x
      Z = Z
    end
  end
  createUI()
  if cardCount ~= 0 then
    Wait.time(function() 
      Wait.condition(
        function() 
          addCardButtons()  
          --for i=1, #resources, 1 do
          --  addCardButton(resources[i].card.getPosition(), resources[i].card.getBoundsNormalized().size, resources[i].state)
          --end
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

function clearCardButtons()
  local oldUI = self.UI.getXmlTable()
  local newUI = {}
  table.insert(newUI, oldUI[1])
  self.UI.setXmlTable(newUI)
end

function addCardButtons()
  local scale = self.getScale()
  local thickness = self.getCustomObject().thickness
  local resources = VARIABLES.resourceCards
  local oldUI = self.UI.getXmlTable()
  local newUI = {}

  table.insert(newUI, oldUI[1])
  --table.insert(newUI, oldUI[2])
  for i=1, #resources, 1 do
    local cardPosition = resources[i].card.getPosition()
    local cardSize = resources[i].card.getBounds().size
    local buttonPosition = Vector(cardPosition) + Vector(-cardSize.x/2,cardSize.y/2,cardSize.z/2)
    local offset = Vector(50,-1,-50)
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

function onReadyButtonClick(_, _, id)

  local i = id:match(self.getGUID().."CardButton(%d+)")
  
  if i ~= nil then
    i = tonumber(i)
    VARIABLES.resourceCards[i].card.setRotationSmooth({0,self.getRotation().y+180,180})
    VARIABLES.resourceCards[i].state = "ready"
    setResources()
  end
end


function onExhaustButtonClick(_, _, id)

  local i = id:match(self.getGUID().."CardButton(%d+)")
  
  if i ~= nil then
    i = tonumber(i)
    for n=1, i, 1 do
      VARIABLES.resourceCards[n].card.setRotationSmooth({0,self.getRotation().y+270,180})
      VARIABLES.resourceCards[n].state = "exhausted"
    end
      setResources()
  end
end

function readyAllCards()
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
            offsetXY = "0 90",
            rotation = "0 0 0",
            color = CONSTANTS.bgColor,
            width = 700,
            height = 515,
            allowDragging = "false",
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
            offsetXY = "0 -260",
            rotation = "0 0 0",
            color = CONSTANTS.bgColor,
            width = 700,
            height = 175,
            allowDragging = "false",
            childAlignment = "LowerRight",
            childForceExpandHeight = "false",
            childForceExpandWidth = "false",
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
  local unlockedCard = false
  for i=1, #VARIABLES.resourceCards, 1 do
    if object == VARIABLES.resourceCards[i].card and VARIABLES.resourceCards[i].state == "unlocked" then
      unlockedCard = true
      break
    end
  end
  if zone.getGUID() == CONSTANTS.resourceScriptingZoneGUID  and not unlockedCard then
    if object.hasTag("Card") and object.type == "Card" then
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
              --state = "ready",
            } 
            table.insert(VARIABLES.resourceCards, resource)
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
          if VARIABLES.resourceCards[i].state == "unlocked" then
            unlockedCard = true
          end
          table.remove(VARIABLES.resourceCards, i)
          break
        end
      end
    end
    if not unlockedCard then
      setResources()
    end
  end
end

--- Print table
function printTable(obj,option)
  if type(obj) ~= 'table' then return obj end
  local res = {}
  for k, v in pairs(obj) do
    if option == "s" then
      print(k..": ",v)
    else
      print(k..": ",printTable(v))
    end
  end
  print("--")
  return res
end