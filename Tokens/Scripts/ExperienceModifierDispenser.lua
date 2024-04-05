--- Configuration table for the token inside the dispenser.
-- These parameters will be set on token leaving the dispenser.
-- Saved onSave and load on Load. 
CONFIG = {
  SHOW_TOOLTIP = false, -- bool: Flag for setting signed values.
  NEGATIVE_VALUES = true, -- bool: Flag for setting sign values.
  SEPARATED = false, -- bool: Flag for setting same values on both counters.
}

--- Loads saved data.
-- TTS API Called when an object is loaded or spawned.
-- Loads configuration table from JSON encoded saved_data if it exists, and
-- create contextual menus.
-- @tparam tab saved_data JSON encoded table
-- @see createMenus
function onLoad(saved_data)
  if saved_data ~= "" then
    local loaded_data = JSON.decode(saved_data)
    CONFIG = loaded_data
  end
  createMenus()
end

--- Saves all the data.
-- TTS API called on save/autosave for every object.
-- Encodes parameter table to JSON and returns it as saved data.
--@treturn tab saved_data JSON encoded table
function onSave()
  local dataToSave = JSON.encode(CONFIG)
  return dataToSave
end


function onObjectLeaveContainer(container, object)
  if container == self then
    object.tooltip = CONFIG.SHOW_TOOLTIP
    -- Using tags because object after leaving container is not fully sawn yet
    if CONFIG.NEGATIVE_VALUES then object.addTag("TokenNegativeValues") end
    if CONFIG.SEPARATED then object.addTag("TokenSeparated") end
  end    
end

function createMenus()
  self.clearContextMenu()

  local showTooltipText = "Show Tooltip: "
  if CONFIG.SHOW_TOOLTIP then
    showTooltipText = showTooltipText .. "ON"
  else
    showTooltipText = showTooltipText .. "OFF"
  end
  self.addContextMenuItem(showTooltipText, onToggleTooltip, false)

  local negativeValuesText = "Negative values: "
  if CONFIG.NEGATIVE_VALUES then
    negativeValuesText = negativeValuesText .. "ON"
  else
    negativeValuesText = negativeValuesText .. "OFF"
  end
  self.addContextMenuItem(negativeValuesText, onToggleNegativeValues, false)

  local separatedText = "Separate values: "
  if CONFIG.SEPARATED then
    separatedText = separatedText .. "ON"
  else
    separatedText = separatedText .. "OFF"
  end
  self.addContextMenuItem(separatedText, onToggleSeparated, false)
end

function onToggleTooltip()
  if CONFIG.SHOW_TOOLTIP then
    CONFIG.SHOW_TOOLTIP = false
  else
    CONFIG.SHOW_TOOLTIP = true
  end
  createMenus()
end

function onToggleNegativeValues()
  if CONFIG.NEGATIVE_VALUES then
    CONFIG.NEGATIVE_VALUES = false
  else
    CONFIG.NEGATIVE_VALUES = true
  end
  createMenus()
end

function onToggleSeparated()
  if CONFIG.SEPARATED then
    CONFIG.SEPARATED = false
  else
    CONFIG.SEPARATED = true
  end
  createMenus()
end