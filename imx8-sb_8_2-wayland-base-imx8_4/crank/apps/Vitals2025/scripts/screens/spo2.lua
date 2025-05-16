-- Utils
local file_utils = require('utils.file_utils')
local get_test_results = require('utils.get_test_results')
-- Components
local pulse_setup = require('components.pulse_setup')

local CSV_FILE = "bidmc_02_Signals.csv"
local CSV_INDEX = 3
local CSV_VALUES = file_utils:load_file(CSV_FILE, CSV_INDEX)

local ANIM_DATA = {
    interval_time = 20,
    path_trim_amount = 10,
}

local DRAW_DATA = {
    x_start = -10,      -- Where to start drawing from
    x_spacing = 3,      -- X spacing between data points
    y_height = -200,    -- how high to draw the grid
    y_offset = 430,     -- shift values down vertically
    graph_width = 510,  -- width of grid
}
local DATA_OFFSET = 50
local MAX_POINTS = ((DRAW_DATA.graph_width - DRAW_DATA.x_start) / DRAW_DATA.x_spacing)

local SETUP_LAYER = "spo2_sc.pulse_setup_layer"
local PLETH_LAYER = "spo2_sc.pleth_layer"
local ANIM_FPS = "spo2_sc.anim_fps"

local DATA_PATHS = {
    poly_string = "pleth_layer.pleth_polystring_%d",
    oxygen_saturation = "pleth_layer.oxygen_saturation",
    heart_rate = "pleth_layer.heart_rate",
    resp_rate = "pleth_layer.resp_rate"
}

local spo2 = {}
spo2.initialized = false
spo2.x_points = {}
spo2.y_points = {}
spo2.results = {}
spo2.peak = false

-- Animation Timers
spo2.lung_anim_interval = nil
spo2.heart_anim_interval = nil

-- Line 1
spo2.line_1_x = {}
spo2.line_1_y = {}
spo2.line_1_counter = 1
spo2.line_1_interval = nil
-- Line 2
spo2.line_2_x = {}
spo2.line_2_y = {}
spo2.line_2_counter = 1
spo2.line_2_interval = nil

--- Load the data from CSV file and plot the points
--- @function spo2:init
function spo2:init()
    local x_pos = DRAW_DATA.x_start

    -- Map all points to their X/Y values
    for i = DATA_OFFSET, (MAX_POINTS + DATA_OFFSET) do
        local value = tonumber(CSV_VALUES[i])
        local y_val = (value * DRAW_DATA.y_height) + DRAW_DATA.y_offset
        table.insert(self.y_points, y_val)
        table.insert(self.x_points, x_pos)
        x_pos = x_pos + DRAW_DATA.x_spacing
    end

    gre.set_value(ANIM_FPS, 0)
end

--- Begin the next polystring line
--- @function spo2:start_next
--- @param line_id number the current line_id
function spo2:start_next(line_id)
    if(line_id == 1) then
        self.line_2_x = {}
        self.line_2_y = {}
        self.line_2_counter = 1
        self.line_2_interval = gre.timer_set_interval(ANIM_DATA.interval_time, function()
            self:update_polystring(2)
        end)
    else
        self.line_1_x = {}
        self.line_1_y = {}
        self.line_1_counter = 1
        self.line_1_interval = gre.timer_set_interval(ANIM_DATA.interval_time, function()
            self:update_polystring(1)
        end)
    end
end

--- End & clear a line
--- @function spo2:end_line
--- @param line_id number the current line_id
function spo2:end_line(line_id)
    if(line_id == 1) then
        gre.timer_clear_interval(self.line_1_interval)
        self.line_1_interval = nil
    else
        gre.timer_clear_interval(self.line_2_interval)
        self.line_2_interval = nil
    end
end

--- Update the give lines polystring value
--- @function spo2:update_polystring
--- @param line_id number
function spo2:update_polystring(line_id)
    local x_table = line_id == 1 and self.line_1_x or self.line_2_x
    local y_table = line_id == 1 and self.line_1_y or self.line_2_y
    local counter = line_id == 1 and self.line_1_counter or self.line_2_counter

    local buffer = (#self.x_points - ANIM_DATA.path_trim_amount)
    local trigger_point = (buffer - ANIM_DATA.path_trim_amount)
    local plus_1 = (counter + 1)

    -- Line is above the buffer, start cropping from the beginning
    if (plus_1 > buffer) then
        -- There are still values to be placed
        if(#x_table > 1) then
            -- We've hit the trigger point to start the next line
            if(#x_table == trigger_point) then
                self:start_next(line_id)
            end

            -- Remove the first x/y values to crop from beginning
            table.remove(x_table, 1)
			table.remove(y_table, 1)

            -- More values at end of line to place
            if(plus_1 < #self.x_points) then
                table.insert(x_table, self.x_points[counter])
                table.insert(y_table, self.y_points[counter])
                counter = plus_1
            end
		else
			self:end_line(line_id)
		end
	else
		table.insert(x_table, self.x_points[counter])
		table.insert(y_table, self.y_points[counter])
		counter = plus_1
	end

    -- Update counter
    if(line_id == 1) then
        self.line_1_counter = counter
    else
        self.line_2_counter = counter
    end

    -- Update GDE
    local poly_string = gre.poly_string(x_table, y_table)
    local path = string.format(DATA_PATHS.poly_string, line_id)
    gre.set_value(path, poly_string)
end

--- Clear the polystring and animations
--- @function spo2:clear_polystring
function spo2:clear_polystring()
    if(self.line_1_interval) then
        gre.timer_clear_interval(self.line_1_interval)
        self.line_1_interval = nil
    end
    if(self.line_2_interval) then
        gre.timer_clear_interval(self.line_2_interval)
        self.line_2_interval = nil
    end

    self.line_1_x = {}
    self.line_1_y = {}
    self.line_1_counter = 1

    self.line_2_x = {}
    self.line_2_y = {}
    self.line_2_counter = 1

    local poly = gre.poly_string({}, {})
    gre.set_data({
        [string.format(DATA_PATHS.poly_string, 1)] = poly,
        [string.format(DATA_PATHS.poly_string, 2)] = poly
    })
end

--- Animate the icons pulsing
--- @function spo2:animate_icons
function spo2:animate_icons()
    math.randomseed(os.time())
    
    -- Heart
    self.heart_anim_interval = gre.timer_set_interval(math.random(6000, 10000), function()
        gre.animation_trigger("pleth_heart_anim")
    end)

    -- Lungs
    self.lung_anim_interval = gre.timer_set_interval(math.random(10000, 15000), function()
        gre.animation_trigger("pleth_lungs_anim")
    end)
end

--- Populate the test results
--- @function spo2:populate_results
function spo2:populate_results()
    gre.set_data({
        [DATA_PATHS.oxygen_saturation] = self.results["oxygen"],
        [DATA_PATHS.heart_rate] = self.results["heart_rate"],
        [DATA_PATHS.resp_rate] = self.results["respiration"],
    })

    if(not MCU_MODE) then
        self:animate_icons()
    end
end

--- The start button has been pressed
--- @function spo2:start
function spo2:start()
    -- Get the random test results
    self.results = get_test_results:generate_results(true)
    self:populate_results()

    -- Reset & begin the line timers
    self:clear_polystring()
    self.line_1_interval = gre.timer_set_interval(ANIM_DATA.interval_time, function()
        self:update_polystring(1)
    end)

    -- Update video FPS
    if(not MCU_MODE) then
        gre.set_value(ANIM_FPS, 30)
    end

    -- Show the pleth layer
    gre.set_data({
        [string.format("%s.grd_hidden", SETUP_LAYER)] = true,
        [string.format("%s.grd_hidden", PLETH_LAYER)] = false,
    })
end

--- The screen has been hidden, reset back to default
--- @function spo2:hide
function spo2:hide()
    pulse_setup:reset()
    self:clear_polystring()

    -- Clear icon intervals
    if(self.lung_anim_interval) then
        gre.timer_clear_interval(self.lung_anim_interval)
        self.lung_anim_interval = nil
    end
    if(self.heart_anim_interval) then
        gre.timer_clear_interval(self.heart_anim_interval)
        self.heart_anim_interval = nil
    end

    -- Update video FPS
    gre.set_value(ANIM_FPS, 0)

    -- Show the setup layer
    gre.set_data({
        [string.format("%s.grd_hidden", SETUP_LAYER)] = false,
        [string.format("%s.grd_hidden", PLETH_LAYER)] = true,
    })
end

return spo2