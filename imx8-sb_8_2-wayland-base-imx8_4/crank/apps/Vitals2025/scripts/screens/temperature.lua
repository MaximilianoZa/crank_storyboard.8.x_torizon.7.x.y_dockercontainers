-- Utils
local get_test_results = require('utils.get_test_results')
local table_utils = require('utils.table_utils')
local score_legend = require('utils.score_legend')

local PATHS = {
    anim_fps = "temperature_sc.anim_fps",
    cur_value = "temp_layer.temp_current_value",
    avg_value = "temp_layer.temp_average_value",
    graph_date = "temp_layer.temp_graph_date",
    temp_val_int = "temp_layer.temp_value_int",
    temp_val_dec = "temp_layer.temp_value_dec",
}

local function generate_average_temperature()
    local upper_range = score_legend["core_temp"]["upper_range"]
    local lower_range = score_legend["core_temp"]["lower_range"]

    local total = 0
    for i=1, 12 do
        total = total + math.random(lower_range, upper_range)
    end

    return (total / 12)
end

local temperature = {}
temperature.results = {}
temperature.average = nil

--- Initialise the temperature screen
--- @function temperature:init
function temperature:init()
    math.randomseed(os.time())
    -- Set animation to be paused
    gre.set_value(PATHS.anim_fps, 0)

    -- Generate a 12-hr 'average' temperature
    self.average = generate_average_temperature()
    gre.set_value(PATHS.avg_value, string.format("%.2fº", self.average))

    -- Set the graph date to today
    gre.set_value(PATHS.graph_date, os.date("%m/%d/%y"))
end

--- Populatre the results onto the temperature screen
--- @function temperature:populate_results
function temperature:populate_results()
    local cur_temp = tostring(self.results["core_temp"])

    local temp_split = table_utils:split_string(cur_temp, ".")
    local int_val = temp_split[1]
    local dec_val = temp_split[2] or 0

    gre.set_data({
        [PATHS.cur_value] = string.format("%sº", cur_temp),
        [PATHS.temp_val_int] = int_val,
        [PATHS.temp_val_dec] = string.format(".%sº", dec_val)
    })
end

--- The temperature screen is about to be shown
--- @function temperature:show
function temperature:show()
    -- Get randomised results
    self.results = get_test_results:generate_results(true)
    self:populate_results()

    -- Update animation FPS
    if(not MCU_MODE) then
        gre.set_value(PATHS.anim_fps, 30)
    end
end

--- The temperature screen has been hidden
--- @function temperature:hide
function temperature:hide()
    -- Update animation FPS
    gre.set_value(PATHS.anim_fps, 0)
end

return temperature