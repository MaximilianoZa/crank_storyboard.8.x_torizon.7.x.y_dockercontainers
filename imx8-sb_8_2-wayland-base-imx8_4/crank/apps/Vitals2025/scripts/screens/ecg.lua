local score_utils = require('utils.score_utils')
local file_utils = require('utils.file_utils')
local table_utils = require('utils.table_utils')
local get_test_results = require('utils.get_test_results')

--local nav_init = nav_scroller.init_nav_bar
local test_results = get_test_results:generate_results(false)

local Y_HEIGHT = -180 -- exaggerates the scale of the y points
local Y_OFFSET = 480 -- shifts the y values down the screen vertically
local DATA_START_INDEX = 108
local GRAPH_WIDTH = 510 -- could get_value then alter that
local GRAPH_X_POS = -10 -- could get_value then alter that
local X_SPACING = 4
local PATH_TRIM_AMOUNT = 30
local MAX_POINTS = (GRAPH_WIDTH - GRAPH_X_POS) / X_SPACING
local INTERVAL_TIME = 30

-- both set when csv data is fetched
local second_line_start
local num_of_data_points

-- generated during csv fetch
local x_points = {}
local y_points = {}

local csv_file = "bidmc_01_ECG.csv"
local csv_values = file_utils:load_file(csv_file)
local initial_data_loaded = false

--- Loads data from .csv file
-- Iterate over the data in a csv file containing ecg data and create two tables
-- one of x values and the other of y values.
local function load_data()
	-- loop through and create x and y coord tables
	local time = GRAPH_X_POS -- the position to start drawing from horizontally
	for i = DATA_START_INDEX, MAX_POINTS + DATA_START_INDEX do
		table.insert(y_points,(tonumber(csv_values[i]) * Y_HEIGHT) + Y_OFFSET)
		table.insert(x_points,time)
		time = time + X_SPACING
	end

	num_of_data_points = #y_points
	second_line_start = (num_of_data_points * INTERVAL_TIME) - ((PATH_TRIM_AMOUNT * INTERVAL_TIME) / 2)
end

local line_1_interval_id = {}
local line_2_timeout_id = {}
local line_2_interval_id = {}

local anim_x_points = {}
local anim_y_points = {}
local counter_1 = { val = 1 }

local anim_x_points_2 = {}
local anim_y_points_2 = {}
local counter_2 = { val = 1 }

local function update_ecg_polystring(x_table, y_table, counter, line_id)
	if (counter.val + 1 > num_of_data_points - PATH_TRIM_AMOUNT) then
		if (#x_table > 1 and counter.val + 1 < num_of_data_points) then
			table.remove(x_table, 1)
			table.remove(y_table, 1)
			table.insert(x_table, x_points[counter.val])
			table.insert(y_table, y_points[counter.val])
			counter.val = counter.val + 1
		elseif (#x_table > 1) then
			table.remove(x_table, 1)
			table.remove(y_table, 1)
		else
			table_utils:clear_table(x_table)
			table_utils:clear_table(y_table)

			counter.val = 1
		end
	else
		table.insert(x_table, x_points[counter.val])
		table.insert(y_table, y_points[counter.val])
		counter.val = counter.val + 1
	end
	local poly_string = gre.poly_string(x_table, y_table)
	gre.set_data({
		["ecg_layer.ecg_polystring_" .. line_id] = poly_string
	})
end

local function ecg_polystring_1_update()
	update_ecg_polystring(anim_x_points, anim_y_points, counter_1, 1)
end

local function ecg_polystring_2_update()
	update_ecg_polystring(anim_x_points_2, anim_y_points_2, counter_2, 2)
end

local function trigger_second_line()
	line_2_timeout_id = {}
	line_2_interval_id = gre.timer_set_interval(INTERVAL_TIME,ecg_polystring_2_update)
end

--- A set of functions for updating the ecg screen results before showing it.
local set_ecg_screen_results = {}

--- Updates the ecg and heart rate scores to the current scores.
function set_ecg_screen_results:text()
	gre.set_data({
		["ecg_layer.ecg_scores"] = test_results.systolic .. "/" .. test_results.diastolic,
		["ecg_layer.heart_rate_score"] = test_results.heart_rate_resting,
	})
end

--- Display ECG scores on a bar.
-- Works very similarly to get_range_in_bar but with slight modifications because
-- of the custom range of the bar (it's different from the lower and upper ranges
-- of the categories).
-- It creates a range on a bar that displays the distance between the systolic
-- and diastolic scores.
function set_ecg_screen_results:chart_bar()
	-- this specific bar has a range of 40 - 180 which isn't the lower or upper range
	-- for either systolic or diastolic, meaning it needs a custom range
	local BP_CHART_UPPER = 180
	local BP_CHART_LOWER = 40
	local INDICATORS_STARTING_POS_Y = 546
	
	local bar_path = "ecg_chart_layer.blood_pressure_chart_group.graph_base"
	local bar_length = gre.get_value(bar_path .. ".grd_height")
	local systolic_indicator_pos
	local diastolic_indicator_pos
	local systolic_score =  test_results.systolic
	local diastolic_score = test_results.diastolic
	
	local diastolic_percentage = score_utils:in_range(BP_CHART_UPPER, BP_CHART_LOWER, diastolic_score)
	local systolic_percentage = score_utils:in_range(BP_CHART_UPPER, BP_CHART_LOWER, systolic_score)
	
	local range_start_val
	local range_end_val
	
	if (diastolic_percentage < systolic_percentage) then
		range_start_val = bar_length * (diastolic_percentage / 100)
		range_end_val = (bar_length * (systolic_percentage / 100)) - range_start_val
		diastolic_indicator_pos = INDICATORS_STARTING_POS_Y - range_start_val
		systolic_indicator_pos = INDICATORS_STARTING_POS_Y - (range_start_val + range_end_val)
	elseif (diastolic_percentage < systolic_percentage) then -- TODO: Duplicate if statement?
		range_start_val = bar_length * (systolic_percentage / 100)
		range_end_val = (bar_length * (diastolic_percentage / 100)) - range_start_val
		diastolic_indicator_pos = INDICATORS_STARTING_POS_Y - (range_start_val + range_end_val)
		systolic_indicator_pos = INDICATORS_STARTING_POS_Y - range_start_val
	end
	
	gre.set_data({
		["ecg_chart_layer.blood_pressure_chart_group.range_start"] = range_start_val,
		["ecg_chart_layer.blood_pressure_chart_group.range_end"] = range_end_val,
		["ecg_chart_layer.blood_pressure_chart_group.systolic_control.grd_y"] = systolic_indicator_pos,
		["ecg_chart_layer.blood_pressure_chart_group.diastolic_control.grd_y"] = diastolic_indicator_pos,
	})
end

local function clear_ecg_line()
	if (type(line_1_interval_id) == "userdata") then
		gre.timer_clear_interval(line_1_interval_id)
		line_1_interval_id = {}
	end
	if (type(line_2_interval_id) == "userdata") then
		gre.timer_clear_interval(line_2_interval_id)
		line_2_interval_id = {}
	end
	if (type(line_2_timeout_id) == "userdata") then
		gre.timer_clear_timeout(line_2_timeout_id)
		line_2_timeout_id = {}
	end
	anim_x_points = {}
	anim_y_points = {}
	counter_1.val = 1

	anim_x_points_2 = {}
	anim_y_points_2 = {}
	counter_2.val = 1

	local poly_string = gre.poly_string({}, {})
	gre.set_data({
		["ecg_layer.ecg_polystring_1"] = poly_string,
		["ecg_layer.ecg_polystring_2"] = poly_string,
	})
end

local function screen_leave_CB()
	clear_ecg_line()
end

local function init_ecg_line_CB(mapargs)
	if (mapargs.context_event_data.ecg_graph_width ~= nil) then
		local new_width = mapargs.context_event_data.ecg_graph_width
		X_SPACING = new_width
		MAX_POINTS = (GRAPH_WIDTH - GRAPH_X_POS) / new_width
		clear_ecg_line()
		x_points = {}
		y_points = {}
		load_data()
		line_1_interval_id = gre.timer_set_interval(INTERVAL_TIME, ecg_polystring_1_update)
		line_2_timeout_id = gre.timer_set_timeout(second_line_start, trigger_second_line)
		return
	end
	clear_ecg_line()
	line_1_interval_id = gre.timer_set_interval(INTERVAL_TIME, ecg_polystring_1_update)
	line_2_timeout_id = gre.timer_set_timeout(second_line_start, trigger_second_line)
end


local function init_CB(mapargs)
	if (not initial_data_loaded) then
		load_data()
	end

	clear_ecg_line()
	set_ecg_screen_results:text()
	set_ecg_screen_results:chart_bar()
end

return { 
	init_CB = init_CB,
	screen_leave_CB = screen_leave_CB,
	init_ecg_line_CB = init_ecg_line_CB
}