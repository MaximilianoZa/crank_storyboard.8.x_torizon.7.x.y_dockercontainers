-- Utils
local get_test_results = require('utils.get_test_results')
local table_utils = require('utils.table_utils')

local PATHS = {
    anim_fps = "insulin_sc.anim_fps",
    -- Display
    glucose_val_int = "insulin_layer.glucose_val_int",
    glucose_val_dec = "insulin_layer.glucose_val_dec",
    -- Bar Chart
    bar_fill = "insulin_layer.blood_sugar_bar_chart.bar_fill",
    bar_marker = "insulin_layer.blood_sugar_bar_chart.bar_marker",
    lipid_tc_val_int = "insulin_layer.lipid_tc_val_int",
    lipid_tc_val_dec = "insulin_layer.lipid_tc_val_dec",
    lipid_tg_val_int = "insulin_layer.lipid_tg_val_int",
    lipid_tg_val_dec = "insulin_layer.lipid_tg_val_dec",
    lipid_hdl_val_int = "insulin_layer.lipid_hdl_val_int",
    lipid_hdl_val_dec = "insulin_layer.lipid_hdl_val_dec",
    lipid_ldl_val_int = "insulin_layer.lipid_ldl_val_int",
    lipid_ldl_val_dec = "insulin_layer.lipid_ldl_val_dec",
    -- Pie Chart
    chart_yellow_1 = "insulin_layer.blood_sugar_rating.chart.yellow_1_alpha",
    chart_yellow_2 = "insulin_layer.blood_sugar_rating.chart.yellow_2_alpha",
    chart_green_1 = "insulin_layer.blood_sugar_rating.chart.green_1_alpha",
    chart_green_2 = "insulin_layer.blood_sugar_rating.chart.green_2_alpha",
    chart_green_3 = "insulin_layer.blood_sugar_rating.chart.green_3_alpha",
    chart_orange_1 = "insulin_layer.blood_sugar_rating.chart.orange_1_alpha",
    chart_orange_2 = "insulin_layer.blood_sugar_rating.chart.orange_2_alpha",
    chart_red_1 = "insulin_layer.blood_sugar_rating.chart.red_1_alpha",
    chart_red_2 = "insulin_layer.blood_sugar_rating.chart.red_2_alpha",
    chart_red_3 = "insulin_layer.blood_sugar_rating.chart.red_3_alpha",
    chart_red_4 = "insulin_layer.blood_sugar_rating.chart.red_4_alpha",
    range_color = "insulin_layer.blood_sugar_rating.range.color",
    range_text = "insulin_layer.blood_sugar_rating.range.text",
}

local CHART_COLOURS = {
    red = 0xc70000,
    orange = 0xf7921e,
    green = 0x00bb42,
}

local CHART_ORDER = {
    { path = PATHS.chart_red_3, val = 2.7, msg = "Critical", colour = CHART_COLOURS.red },
    { path = PATHS.chart_red_4, val = 3.1, msg = "Poor", colour = CHART_COLOURS.red },

    { path = PATHS.chart_yellow_1, val = 3.5, msg = "Moderate", colour = CHART_COLOURS.orange },
    { path = PATHS.chart_yellow_2, val = 3.9, msg = "Good", colour = CHART_COLOURS.orange },

    { path = PATHS.chart_green_1, val = 4.3, msg = "Excellent", colour = CHART_COLOURS.green },
    { path = PATHS.chart_green_2, val = 4.7, msg = "Excellent", colour = CHART_COLOURS.green },
    { path = PATHS.chart_green_3, val = 5.1, msg = "Excellent", colour = CHART_COLOURS.green },

    { path = PATHS.chart_orange_1, val = 5.6, msg = "Good", colour = CHART_COLOURS.orange },
    { path = PATHS.chart_orange_2, val = 6, msg = "Moderate", colour = CHART_COLOURS.orange },

    { path = PATHS.chart_red_1, val = 6.4, msg = "Poor", colour = CHART_COLOURS.red },
    { path = PATHS.chart_red_2, val = 6.8, msg = "Critical", colour = CHART_COLOURS.red },
}

local BAR_BASE_Y = 488
local BAR_BASE_HEIGHT = 0
local BAR_BASE_MG = 2.2
local BAR_HEIGHT_PER_MG = 22.3

local ALPHA_SHOW = 255
local ALPHA_DISABLED = 84

local insulin = {}
insulin.results = {}

--- Get the value split between int and dec value
--- @function insulin:get_value_split
--- @param key string the result key to get value from
--- @return table split
function insulin:get_value_split(key)
    local value = tostring(self.results[key])
    local split = table_utils:split_string(value, ".")
    local dec = string.format(".%d", (split[2] or 0))
    return { int = split[1], dec = dec }
end

--- Populate the data
--- @function insulin:populate_data
function insulin:populate_data()
    local data = {}

    -- Display
    local blood_sugar = self:get_value_split("blood_sugar")
    data[PATHS.glucose_val_int] = blood_sugar.int
    data[PATHS.glucose_val_dec] = blood_sugar.dec

    -- Lipids
    local tc_val = self:get_value_split("blood_tc")
    local tg_val = self:get_value_split("blood_tg")
    local ldl_val = self:get_value_split("blood_ldl")
    local hdl_val = self:get_value_split("blood_hdl")
    data[PATHS.lipid_tc_val_int] = tc_val.int
    data[PATHS.lipid_tc_val_dec] = tc_val.dec
    data[PATHS.lipid_tg_val_int] = tg_val.int
    data[PATHS.lipid_tg_val_dec] = tg_val.dec
    data[PATHS.lipid_ldl_val_int] = ldl_val.int
    data[PATHS.lipid_ldl_val_dec] = ldl_val.dec
    data[PATHS.lipid_hdl_val_int] = hdl_val.int
    data[PATHS.lipid_hdl_val_dec] = hdl_val.dec

    gre.set_data(data)
end

--- Populate the bar chart
--- @function insulin:populate_bar_chart
function insulin:populate_bar_chart()
    local value = self.results["blood_sugar"]
    local height = (value - BAR_BASE_MG) * BAR_HEIGHT_PER_MG
    local fill_y = (BAR_BASE_Y - height)

    local data = {}
    data[string.format("%s.grd_height", PATHS.bar_fill)] = height
    data[string.format("%s.grd_y", PATHS.bar_fill)] = fill_y
    data[string.format("%s.grd_y", PATHS.bar_marker)] = fill_y - 10

    gre.set_data(data)
end

--- Populate the rating chart
--- @function insulin:populate_rating_chart
function insulin:populate_rating_chart()
    local value = self.results["blood_sugar"]
    local highlight = false

    -- Loop through each segment, determine if value fits
    local data = {}
    for _, segment in ipairs(CHART_ORDER) do
        data[segment.path] = ALPHA_DISABLED

        if(not highlight and value < segment.val) then
            data[segment.path] = ALPHA_SHOW
            data[PATHS.range_color] = segment.colour
            data[PATHS.range_text] = segment.msg
            highlight = true
        end
    end

    -- If no segment selected, value is above the final one
    if(not highlight) then
        local segment = CHART_ORDER[#CHART_ORDER]
        data[segment.path] = ALPHA_SHOW
        data[PATHS.range_color] = segment.colour
        data[PATHS.range_text] = segment.msg
    end

    gre.set_data(data)
end

--- The insulin screen is being shown
--- @function insulin:show
function insulin:show()
    self.results = get_test_results:generate_results(true)

    -- Set animation FPS
    if(not MCU_MODE) then
        gre.set_value(PATHS.anim_fps, 30)
    end

    -- Populate generated data
    self:populate_data()
    self:populate_bar_chart()
    self:populate_rating_chart()
end

--- Reset the insulin screen
--- @function insulin:reset
function insulin:reset()
    local data = {}

    -- Set anim fps
    data[PATHS.anim_fps] = 0

    -- Reset bar chart
    data[string.format("%s.grd_height", PATHS.bar_fill)] = BAR_BASE_HEIGHT
    data[string.format("%s.grd_y", PATHS.bar_fill)] = BAR_BASE_Y
    data[string.format("%s.grd_y", PATHS.bar_marker)] = BAR_BASE_Y - 10

    gre.set_data(data)
end

--- The insulin screen has been hidden
--- @function insulin:hide
function insulin:hide()
    self:reset()
end

--- Initialize the insulin screen
--- @function insulin:init
function insulin:init()
    self:reset()
end

return insulin