--- Configuration table.
-- Saved onSave and load on Load. 
CONFIG = {
  MIN_VALUE = 1, -- number: Minimal value of the counters.
  MAX_VALUE = 99, -- number: Maximal value of the counters.
  FONT_COLOR = "#ffffff", -- string: Text color  of the counters.
  FONT_SIZE = 177, -- number: Font size of the counters.
  TOOLTIP_SHOW = false, -- bool: Force tooltip visibility if Tooltip is disable in Toggles.
  VALUE = 1 -- number: Current value of the counter.
}

--- Loads saved data.
-- TTS API Called when an object is loaded or spawned.
-- Loads configuration table from JSON encoded saved_data if it exists, and
-- create counter.
-- @tparam tab saved_data JSON encoded table
-- @see createAll
function onload(saved_data)
  if saved_data ~= "" then
    local loaded_data = JSON.decode(saved_data)
    CONFIG.VALUE = loaded_data.VALUE
  end
  createAll()
end

--- Updates saved data of the token.
function updateSave()
  local dataToSave = JSON.encode(CONFIG)
  self.script_state = dataToSave
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
  local textPosition = Vector(19.290339, -50*thickness-0.5, -10.737956)
  
  -- Assets bundle with embedded font
  -- https://www.fontsquirrel.com/fonts/akashi
  self.UI.setCustomAssets({
    {
      name = "swu_fonts",
      type = 1,
      url = "http://cloud-3.steamusercontent.com/ugc/2495630600676732733/1D6C10FBA89CC00A780064FA379482057590D787/"
    },
  })
  
  -- Set value on xml UI text field
  self.UI.setXmlTable({
    {
      tag = "Text",
      attributes = {
        id = "Text" .. self.getGUID(),
        position = textPosition.x .. " " .. textPosition.z.. " " .. textPosition.y,
        rotation = "0 0 180",
        scale =  "1 1 1",
        color = CONFIG.FONT_COLOR,
        text = tostring(CONFIG.VALUE),
        fontSize = math.floor(CONFIG.FONT_SIZE),
        font = "swu_fonts/Akashi",
      },      
    }
  })
  
  -- Invisible clickable button
  self.createButton({
    click_function = "add_subtract",
    tooltip = setTooltips(),
    function_owner = self,
    position = textPosition:copy():scale(Vector(-0.01,-0.01,0.01)),
    rotation = {0,0,0},
    height = 900,
    width =  700,
    color = {0,0,0,0}
  })
end

--- Modify value of the counter.
-- @tparam bool alt_click RMB flag.
-- @see updateVal
-- @see updateSave
function add_subtract(_, _, alt_click)
  mod = alt_click and -1 or 1
  new_value = math.min(math.max(CONFIG.VALUE + mod, CONFIG.MIN_VALUE), CONFIG.MAX_VALUE)
  if CONFIG.VALUE ~= new_value then
    CONFIG.VALUE = new_value
    updateVal()
    updateSave()
  end
end

--- Updates the text value of the UI and tooltip of the button.
function updateVal() 
  self.UI.setAttribute("Text" .. self.getGUID(), "text", CONFIG.VALUE)
  self.UI.setAttribute("Text" .. self.getGUID(), "textColor", CONFIG.FONT_COLOR)
  self.editButton({
    index = 0,
    tooltip = setTooltips(),
  }) 
end

--- Generates tooltip for buttons.
function setTooltips()
  local tooltips = self.tooltip
  local name = self.getName()
  local description = self.getDescription()
  if name == "" then name = "No name" end
  if description == "" then description = "(LMB: +, RMB: -)" end
  
  if tooltips or CONFIG.TOOLTIP_SHOW then
    ttText = name.. ": " .. CONFIG.VALUE .. string.char(10) .. "-----" .. string.char(10) .. description
  else
    ttText = name.. ": " .. CONFIG.VALUE
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
      tooltip = setTooltips(),
    })
  end
end