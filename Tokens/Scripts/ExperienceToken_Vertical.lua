CONFIG = {
    MIN_VALUE = 1,
    MAX_VALUE = 9,
    NEGATIVE_VALUES = false,
    FONT_COLOR = "#ffffff",
    FONT_SIZE = 107,
    TOOLTIP_SHOW = false, -- force tooltip visibility if Tooltip is disable in Toggles
    VALUE1 = 1,
    VALUE2 = 1,
    SEPARATED = false -- false: same value on both counters
}

function onload(saved_data)
    if saved_data ~= "" then
        local loaded_data = JSON.decode(saved_data)
        CONFIG = loaded_data
    end
    createAll()
end

function onSave()
    dataToSave = JSON.encode(CONFIG)
    return dataToSave
end

function createAll()
    local scale = self.getScale()
    local thickness = self.getCustomObject().thickness

    local textPosition1 = Vector(27.247924, -50*thickness-0.5, -83.634082)
    local textPosition2 = Vector(-34.475270, -50*thickness-0.5, 80.532723)

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

function add_subtract(_obj, _color, alt_click)
    mod = alt_click and -1 or 1
    new_value = math.min(math.max(CONFIG.VALUE1 + mod, CONFIG.MIN_VALUE), CONFIG.MAX_VALUE)
    if not CONFIG.SEPARATED and CONFIG.VALUE1 ~= new_value then
        CONFIG.VALUE1 = new_value
        CONFIG.VALUE2 = new_value
        updateVal()
    end
end

function add_subtract1(_obj, _color, alt_click)
    mod = alt_click and -1 or 1
    new_value = math.min(math.max(CONFIG.VALUE1 + mod, CONFIG.MIN_VALUE), CONFIG.MAX_VALUE)
    if CONFIG.VALUE1 ~= new_value then
        CONFIG.VALUE1 = new_value
        updateVal()
    end
end

function add_subtract2(_obj, _color, alt_click)
    mod = alt_click and -1 or 1
    new_value = math.min(math.max(CONFIG.VALUE2 + mod, CONFIG.MIN_VALUE), CONFIG.MAX_VALUE)
    if CONFIG.VALUE2 ~= new_value then
        CONFIG.VALUE2 = new_value
        updateVal()
    end
end

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

-- Use for updating button tooltip 
function onObjectHover(_, object)
    if object == self then
        self.editButton({
            index = 0,
            tooltip = setTooltips()
        })
    end
end

function setSeparated(value)
    CONFIG.SEPARATED = value
    if not value then
        CONFIG.VALUE2 = CONFIG.VALUE1
    end
    createAll()
end

function setNegative(value)
    CONFIG.NEGATIVE_VALUES = value
    if value then
        CONFIG.MIN_VALUE = -1 * CONFIG.MAX_VALUE
    else
        CONFIG.MIN_VALUE = 1
    end
end

