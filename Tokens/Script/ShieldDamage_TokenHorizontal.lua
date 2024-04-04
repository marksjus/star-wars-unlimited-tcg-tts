    CONFIG = {
        MIN_VALUE = 1,
        MAX_VALUE = 99,
        FONT_COLOR = "#ffffff",
        FONT_SIZE = 177,
        TOOLTIP_SHOW = false, -- force tooltip visibility if Tooltip is disable in Toggles
        VALUE = 1
    }

    function onload(saved_data)
        if saved_data ~= "" then
            local loaded_data = JSON.decode(saved_data)
            CONFIG.VALUE = loaded_data.VALUE
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
        local textPosition = Vector(11.811738, -50*thickness-0.5, -16.879031)

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

    function add_subtract(_obj, _color, alt_click)
        mod = alt_click and -1 or 1
        new_value = math.min(math.max(CONFIG.VALUE + mod, CONFIG.MIN_VALUE), CONFIG.MAX_VALUE)
        if CONFIG.VALUE ~= new_value then
            CONFIG.VALUE = new_value
            updateVal()
        end
    end

    function updateVal() 
        self.UI.setAttribute("Text" .. self.getGUID(), "text", CONFIG.VALUE)
        self.UI.setAttribute("Text" .. self.getGUID(), "textColor", CONFIG.FONT_COLOR)
        self.editButton({
            index = 0,
            tooltip = setTooltips(),
        }) 
    end

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

    -- Use for updating button tooltip 
    function onObjectHover(_, object)
        if object == self then
            self.editButton({
                index = 0,
                tooltip = setTooltips(),
            })
        end
    end
