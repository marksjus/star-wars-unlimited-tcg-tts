--- Configuration table.
-- Saved onSave and load on Load. 
CONFIG = {
  MIN_VALUE = 1, -- number: Minimal value of the counters.
  MAX_VALUE = 9, -- number: Maximal value of the counters.
  NEGATIVE_VALUES = false, -- bool: Flag for toggling signed values.
  FONT_COLOR = "#ffffff", -- string: Text color  of the counters.
  FONT_SIZE = 107, -- number: Font size of the counters.
  TOOLTIP_SHOW = false, -- bool: Force tooltip visibility if Tooltip is disable in Toggles.
  VALUE1 = 1, -- number: Current value of the first counter.
  VALUE2 = 1, -- number: Current value of the second counter.
  SEPARATED = false -- bool: Flag for toggling same values on both counters.
}

--- Loads saved data.
-- TTS API Called when an object is loaded or spawned.
-- Loads configuration table from JSON encoded saved_data if it exists,
-- sets TOOLTIP_SHOW, NEGATIVE_VALUES and SEPARATED based on tags, and
-- create counters.
-- @tparam tab saved_data JSON encoded table
-- @see createAll
function onload(saved_data)
  if saved_data ~= "" then
    local loaded_data = JSON.decode(saved_data)
    CONFIG = loaded_data
  end
  -- Configuration tags are added by the dispenser.
  -- We using tags because object after leaving container is 
  -- not fully spawn yet
  if self.hasTag("TokenNegativeValues") then 
    setNegative(true)
  else
    setNegative(false)
  end
  
  if self.hasTag("TokenSeparated") then 
    setSeparated(true)
  else
    setSeparated(false)
  end
  
  createAll()
end

--- Saves all the data.
-- TTS API called on save/autosave for every object.
-- Encodes parameter table to JSON and returns it as saved data.
--@treturn tab saved_data JSON encoded table
function onSave()
  local dataToSave = JSON.encode(CONFIG)
  return dataToSave
end

--- Creates counters.
function createAll()
  local scale = self.getScale()
  
  local thickness = self.getCustomObject().thickness
  local textPosition1 = Vector(70.689711, -50 * thickness - 0.5, -48.431581)
  local textPosition2 = Vector(-67.243283, -50 * thickness - 0.5, 56.655812)
  
  local text1 = tostring(CONFIG.VALUE1)
  local text2 = tostring(CONFIG.VALUE2)
  if CONFIG.VALUE1 > 0 then
    text1 = "+" .. text1
  end
  if CONFIG.VALUE2 > 0 then
    text2 = "+" .. text2
  end
  
  -- Assets bundle with embedded font
  -- https://www.fontsquirrel.com/fonts/akashi
  self.UI.setCustomAssets({{
    name = "swu_fonts",
    type = 1,
    url = "http://cloud-3.steamusercontent.com/ugc/2495630600676732733/1D6C10FBA89CC00A780064FA379482057590D787/"
  }})
  
  -- Set value on two xml UI text field
  self.UI.setXmlTable({{
    tag = "Text",
    attributes = {
      id = "Text1" .. self.getGUID(),
      position = textPosition1.x .. " " .. textPosition1.z .. " " .. textPosition1.y,
      rotation = "0 0 180",
      scale = "1 1 1",
      color = CONFIG.FONT_COLOR,
      text = text1,
      fontSize = math.floor(CONFIG.FONT_SIZE),
      font = "swu_fonts/Akashi"
    }
  }, {
    tag = "Text",
    attributes = {
      id = "Text2" .. self.getGUID(),
      position = textPosition2.x .. " " .. textPosition2.z .. " " .. textPosition2.y,
      rotation = "0 0 180",
      scale = "1 1 1",
      color = CONFIG.FONT_COLOR,
      text = text2,
      fontSize = math.floor(CONFIG.FONT_SIZE),
      font = "swu_fonts/Akashi"
    }
  }})
  
  if CONFIG.SEPARATED then
    -- Two separate invisible button
    self.createButton({
      click_function = "add_subtract1",
      tooltip = setTooltips(),
      function_owner = self,
      position = textPosition1:copy():scale(Vector(-0.01, -0.01, 0.01)),
      rotation = {0, 0, 0},
      height = 600,
      width = 600,
      color = {0, 0, 0, 0}
    })
    self.createButton({
      click_function = "add_subtract2",
      tooltip = setTooltips(),
      function_owner = self,
      position = textPosition2:copy():scale(Vector(-0.01, -0.01, 0.01)),
      rotation = {0, 0, 0},
      height = 600,
      width = 600,
      color = {0, 0, 0, 0}
    })
  else
    -- One shared invisible button
    self.createButton({
      click_function = "add_subtract",
      tooltip = setTooltips(),
      function_owner = self,
      position = {0, 0.5 * thickness, 0},
      rotation = {0, 0, 0},
      height = 700,
      width = 700,
      color = {0, 0, 0, 0}
    })
  end
end

--- Modify value of both counters.
-- @tparam bool alt_click RMB flag.
-- @see updateVal
function add_subtract(_, _, alt_click)
  local mod = alt_click and -1 or 1
  local new_value = math.min(math.max(CONFIG.VALUE1 + mod, CONFIG.MIN_VALUE), CONFIG.MAX_VALUE)
  if not CONFIG.SEPARATED and CONFIG.VALUE1 ~= new_value then
    CONFIG.VALUE1 = new_value
    CONFIG.VALUE2 = new_value
    updateVal()
  end
end

--- Modify value of the first counter and call for updateVal.
-- @tparam bool alt_click RMB flag.
-- @see updateVal
function add_subtract1(_, _, alt_click)
  local mod = alt_click and -1 or 1
  local new_value = math.min(math.max(CONFIG.VALUE1 + mod, CONFIG.MIN_VALUE), CONFIG.MAX_VALUE)
  if CONFIG.VALUE1 ~= new_value then
    CONFIG.VALUE1 = new_value
    updateVal()
  end
end

--- Modify value of the second counter and call for updateVal.
-- @tparam bool alt_click RMB flag.
-- @see updateVal
function add_subtract2(_, _, alt_click)
  local mod = alt_click and -1 or 1
  local new_value = math.min(math.max(CONFIG.VALUE2 + mod, CONFIG.MIN_VALUE), CONFIG.MAX_VALUE)
  if CONFIG.VALUE2 ~= new_value then
    CONFIG.VALUE2 = new_value
    updateVal()
  end
end

--- Updates text values of the UI and tooltip of buttons.
function updateVal()
  
  local text1 = tostring(CONFIG.VALUE1)
  local text2 = tostring(CONFIG.VALUE2)
  if CONFIG.VALUE1 > 0 then
    text1 = "+" .. text1
  end
  if CONFIG.VALUE2 > 0 then
    text2 = "+" .. text2
  end
  
  self.UI.setAttribute("Text1" .. self.getGUID(), "text", text1)
  self.UI.setAttribute("Text1" .. self.getGUID(), "textColor", CONFIG.FONT_COLOR)
  self.UI.setAttribute("Text2" .. self.getGUID(), "text", text2)
  self.UI.setAttribute("Text2" .. self.getGUID(), "textColor", CONFIG.FONT_COLOR)
  self.editButton({
    index = 0,
    tooltip = setTooltips()
  })
  
end

--- Generates tooltip for buttons.
function setTooltips()
  local tooltips = self.tooltip
  local name = self.getName()
  local description = self.getDescription()
  if name == "" then
    name = "No name"
  end
  if description == "" then
    description = "(LMB: +, RMB: -)"
  end
  
  if tooltips or CONFIG.TOOLTIP_SHOW then
    ttText = name .. ": " .. CONFIG.VALUE1 .. string.char(10) .. "-----" .. string.char(10) .. description
  else
    ttText = name .. ": " .. CONFIG.VALUE1
  end
  
  return ttText
end

--- Mouseover behavior.
-- Use for updating button tooltip if changed by the user in contextual menu.
-- @tparam object object Object the player's pointer is hovering over, or nil when a player moves their pointer such that it is no longer hovering over an object.
function onObjectHover(_, object)
  if object == self then
    self.editButton({
      index = 0,
      tooltip = setTooltips()
    })
  end
end

--- Sets SEPARATED value in configuration table.
-- @tparam bool value Separated flag.
function setSeparated(value)
  CONFIG.SEPARATED = value
  if not value then
    CONFIG.VALUE2 = CONFIG.VALUE1
  end
end

--- Sets NEGATIVE_VALUES value in configuration table.
-- @tparam bool value Negative values flag.
function setNegative(value)
  CONFIG.NEGATIVE_VALUES = value
  if value then
    CONFIG.MIN_VALUE = -1 * CONFIG.MAX_VALUE
  else
    CONFIG.MIN_VALUE = 1
  end
end
