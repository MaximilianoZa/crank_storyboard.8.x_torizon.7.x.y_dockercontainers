-- Utils
local file_utils = require('utils.file_utils')
local score_utils = require('utils.score_utils')
local get_test_results = require('utils.get_test_results')

local CSV_FILE = "bidmc_01_ECG.csv"
local CSV_INDEX = 1
local CSV_VALUES = file_utils:load_file(CSV_FILE, CSV_INDEX)

local BAR_DATA = {
    chart_upper = 180,
    chart_lower = 40,
    indicator_start_y = 546,
}

local ANIM_DATA = {
    interval_time = 30,
    path_trim_amount = 15,
}

local DRAW_DATA = {
    x_start = -10,      -- Where to start drawing from
    x_spacing = 4,      -- X spacing between data points
    y_height = -180,    -- how high to draw the grid
    y_offset = 480,     -- shift values down vertically
    graph_width = 510,  -- width of grid
}
local DATA_OFFSET = 108
local MAX_POINTS = ((DRAW_DATA.graph_width - DRAW_DATA.x_start) / DRAW_DATA.x_spacing)

local DATA_PATHS = {
    poly_string = "ecg_layer.ecg_polystring_%d",
    ecg_scores = "ecg_layer.ecg_scores",
    heart_rate_score = "ecg_layer.heart_rate_score",

    bar_chart = "ecg_chart_layer.blood_pressure_chart_group.graph_base",
    bar_range_y = "ecg_chart_layer.blood_pressure_chart_group.graph_range.grd_y",
    bar_range_height = "ecg_chart_layer.blood_pressure_chart_group.graph_range.grd_height",
    bar_systolic_y = "ecg_chart_layer.blood_pressure_chart_group.systolic_control.grd_y",
    bar_diastolic_y = "ecg_chart_layer.blood_pressure_chart_group.diastolic_control.grd_y",
}

local ecg2 = {}
ecg2.initialized = false
ecg2.x_points = {}
ecg2.y_points = {}
ecg2.results = {}

-- Line 1
ecg2.line_1_x = {}
ecg2.line_1_y = {}
ecg2.line_1_counter = 1
ecg2.line_1_interval = nil
-- Line 2
ecg2.line_2_x = {}
ecg2.line_2_y = {}
ecg2.line_2_counter = 1
ecg2.line_2_interval = nil

--- Load the data from CSV file and plot the points
--- @function ecg2:init
function ecg2:init()
    local x_pos = DRAW_DATA.x_start

    -- Map all points to their X/Y values
    for i = DATA_OFFSET, (MAX_POINTS + DATA_OFFSET) do
        local value = tonumber(CSV_VALUES[i])
        local y_val = (value * DRAW_DATA.y_height) + DRAW_DATA.y_offset
        table.insert(self.y_points, y_val)
        table.insert(self.x_points, x_pos)
        x_pos = x_pos + DRAW_DATA.x_spacing
    end
end

--- Begin the next polystring line
--- @function ecg2:start_next
--- @param line_id number the current line_id
function ecg2:start_next(line_id)
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
--- @function ecg2:end_line
--- @param line_id number the current line_id
function ecg2:end_line(line_id)
    if(line_id == 1) then
        gre.timer_clear_interval(self.line_1_interval)
        self.line_1_interval = nil
    else
        gre.timer_clear_interval(self.line_2_interval)
        self.line_2_interval = nil
    end
end

--- Update the give lines polystring value
--- @function ecg2:update_polystring
--- @param line_id number
function ecg2:update_polystring(line_id)
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
--- @function ecg2:clear_polystring
function ecg2:clear_polystring()
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

--- Populate the bar chart
--- @function ecg2:populate_bar_chart
function ecg2:populate_bar_chart()
	local bar_length = gre.get_value(string.format("%s.grd_height", DATA_PATHS.bar_chart))
	local systolic_score =  self.results["systolic"]
	local diastolic_score = self.results["diastolic"]
	
	local diastolic_percentage = score_utils:in_range(BAR_DATA.chart_upper, BAR_DATA.chart_lower, diastolic_score)
	local systolic_percentage = score_utils:in_range(BAR_DATA.chart_upper, BAR_DATA.chart_lower, systolic_score)
	
    local range_start_val = bar_length * (diastolic_percentage / 100)
	local range_end_val = (bar_length * (systolic_percentage / 100)) - range_start_val
	local diastolic_indicator_pos = BAR_DATA.indicator_start_y - range_start_val
	local systolic_indicator_pos = BAR_DATA.indicator_start_y - (range_start_val + range_end_val)
	
	gre.set_data({
        [DATA_PATHS.bar_range_y] = systolic_indicator_pos + 10,
        [DATA_PATHS.bar_range_height] = (diastolic_indicator_pos - systolic_indicator_pos),
		[DATA_PATHS.bar_systolic_y] = systolic_indicator_pos,
		[DATA_PATHS.bar_diastolic_y] = diastolic_indicator_pos,
	})
end

--- Populate the test results
--- @function ecg2:populate_results
function ecg2:populate_results()
    local ecg_score = string.format("%s/%s", self.results['systolic'], self.results["diastolic"])

    gre.set_data({
        [DATA_PATHS.ecg_scores] = ecg_score,
        [DATA_PATHS.heart_rate_score] = self.results["heart_rate_resting"],
    })
    self:populate_bar_chart()
end

--- The screen has been shown
--- @function ecg2:show
function ecg2:show()
    -- Get the random test results
    self.results = get_test_results:generate_results(true)
    self:populate_results()

    -- Reset & begin the line timers
    self:clear_polystring()
    self.line_1_interval = gre.timer_set_interval(ANIM_DATA.interval_time, function()
        self:update_polystring(1)
    end)
end

--- The screen has been hidden, reset back to default
--- @function ecg2:hide
function ecg2:hide()
    self:clear_polystring()
end

return ecg2