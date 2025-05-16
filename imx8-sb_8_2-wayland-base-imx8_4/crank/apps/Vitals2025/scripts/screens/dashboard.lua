local score_range_legend = require('utils.score_legend')
local score_utils = require('utils.score_utils')
local get_test_results = require('utils.get_test_results')
local update_dashboard_results = require('utils.update_dashboard_results')

local graph_modes = { "score_in_range", "category_score" }
local current_mode = graph_modes[2] -- change this to change what the bars show

local test_results = get_test_results:generate_results(true)

local DASHBOARD_CATEGORIES = { "ecg", "spo2", "core_temp", "blood_sugar" }
local TEST_RESULTS_BLANK = {
	["systolic"] = "000",
	["diastolic"] = "00",
	["spo2"] = "00",
	["core_temp"] = "00.0",
	["blood_sugar"] = "0.0"
}

local testing_anim_id = {
	["bars"] = {},
	["circle"] = {}
}

local test_results_formatted = {}
--- Formats then sets the test result data.
local function format_test_results(input_table, testing_bool)
	local current_result_table = input_table

	-- lua 5.1 doesn't show .0 floats for whole numbers so they need to be added
	local function format_with_float(key)
		local formatted_num
		local blank_num = TEST_RESULTS_BLANK[key]
		local with_float_num = string.format("%.1f", current_result_table[key])
		formatted_num = testing_bool == true and blank_num or with_float_num
		return formatted_num
	end

	for index, value in pairs(DASHBOARD_CATEGORIES) do
		if value == "ecg" then
			test_results_formatted[value] =
					current_result_table["systolic"]
					.. "/" ..
					current_result_table["diastolic"]
		elseif value == "core_temp" or value == "blood_sugar" then
			test_results_formatted[value] = format_with_float(value)
		else
			test_results_formatted[value] = current_result_table[value]
		end
		update_dashboard_results:set_test_result_data(
			value,
			test_results_formatted[value]
		)
	end
end



-- Categories that are out of range are added by update_health_score(), these are
-- then looped over by the warning icon animator to show relevant warning signs.
local out_of_target_categories = {}
local function warning_icon_animation(clear_bool)
	local opacity
	opacity = clear_bool == false and 255 or 0

	local animation_id = gre.animation_create(30, 1)
	local anim_data = {}

	for index, val in ipairs(out_of_target_categories) do
		anim_data["rate"] = "linear"
		anim_data["duration"] = 200
		anim_data["to"] = opacity
		anim_data["key"] = "infographic_layer.icn_alert." .. val .. "_alpha"
		anim_data["offset"] = 100
		gre.animation_add_step(animation_id, anim_data)
		anim_data = {}
	end

	if (#out_of_target_categories > 0) then
		anim_data["rate"] = "linear"
		anim_data["duration"] = 200
		anim_data["to"] = opacity
		anim_data["key"] = "infographic_layer.marker_target_max_control.active_alpha"
		anim_data["offset"] = 100
		gre.animation_add_step(animation_id, anim_data)
		anim_data = {}
	end

	gre.animation_trigger(animation_id)

	if (clear_bool == true) then
		out_of_target_categories = {}
	end
end


--- Update the total score in the middle of the infographic.
-- The score is a combination of all the category scores (ecg is combined) then
-- divided by the four categories displayed ont the dashboard. This function also
-- inserts the categories that are beyond the accepted scores in to a table
-- that the warning icons use.
-- @function update_health_score
local function update_health_score()
	local health_score = 0
	local num_of_categories = 0

	for index, value in ipairs(DASHBOARD_CATEGORIES) do
		num_of_categories = num_of_categories + 1
		local category_score = score_utils:get_category_score(value)
		health_score = health_score + category_score.score
		gre.set_data({
			["dashboard_results.".. value .."_message_txt"] = category_score.msg,
		})
		-- Gathering warning data
		if (category_score.score < 100 and current_mode == "score_in_range") then
			table.insert(out_of_target_categories, value)
		elseif (category_score.score < 75 and current_mode == "category_score") then
			table.insert(out_of_target_categories, value)
		end
	end

	local total_health_score = math.floor(health_score / num_of_categories)
	gre.set_data({
		["dashboard_results.health_score_result_txt"] = total_health_score
	})
end



local BAR_GROUP_HEIGHT = {
	["ecg"] = {
		["arc_height"] = 486,
	},
	["spo2"] = {
		["arc_height"] = 408,
	},
	["core_temp"] = {
		["arc_height"] = 326,
	},
	["blood_sugar"] = {
		["arc_height"] = 248,
	},
}



local function add_bar_anim_step(group_key, arc_height, offset_val, score_percentage, dur, testing_bool)
	local test_percentage = score_percentage
	local path_to_group = "infographic_layer." .. group_key .. "_bar_group."
	local fill_max = arc_height + 183 -- 183 is the length of the fill
	local arc_max = 180 + (183 / (arc_height / 180))

	-- set the fill based on percentage
	local ecg_fill_width = fill_max * (test_percentage / 100)
	local ecg_arc_angle = ecg_fill_width / (fill_max / arc_max)

	local duration = dur and dur or 1500

	local anim_data = {}
	anim_data["rate"] = "out_quint"
	anim_data["duration"] = duration
	anim_data["to"] = testing_bool == false and ecg_fill_width or 0
	anim_data["offset"] = dur == 0 and 0 or offset_val
	anim_data["key"] = path_to_group .. "fill"
	gre.animation_add_step(testing_anim_id.bars, anim_data)
	anim_data = {}

	anim_data["rate"] = "out_quint"
	anim_data["duration"] = duration
	anim_data["to"] = testing_bool == false and ecg_arc_angle or 0
	anim_data["offset"] = dur == 0 and 0 or offset_val
	anim_data["key"] = path_to_group .. "arc"
	gre.animation_add_step(testing_anim_id.bars, anim_data)
	anim_data = {}
end



-- sets the gray segments on the bars showing the target ranges
local function set_bar_ranges(group_key, arc_height, start_percentage, end_percentage)
	local path_to_group = "infographic_layer." .. group_key .. "_bar_group."
	local fill_max = arc_height + 183 -- 183 is the length of the fill
	local arc_max = 180 + (183 / (arc_height / 180))

	local range_fill_offset = fill_max * (start_percentage / 100)

	local range_fill_start = (arc_height * -1) + (fill_max * (start_percentage / 100))
	local range_arc_start = (range_fill_start + arc_height) / (fill_max / arc_max)

	local range_fill_end = (fill_max * (end_percentage / 100)) - range_fill_offset
	local range_arc_end = (range_fill_end + range_fill_offset) / (fill_max / arc_max)

	return gre.set_data({
		[path_to_group .. "range_fill_end"] = range_fill_end,
		[path_to_group .. "range_arc_end"] = range_arc_end,
		[path_to_group .. "range_fill_start"] = range_fill_start,
		[path_to_group .. "range_arc_start"] = range_arc_start,
	})
end



local offset = 50
local infographic_bars_init = false

--- Animates the curved bars.
-- Create animations for each bar category then triggers them.
-- @function infographic_bar_animation
-- @param dur Duration, if 0 the update is immediate.
-- @param results_table Table of results to iterate over.
-- @param legend Legend that's used to determine how the current score is displayed.
-- @param testing_bool Bool used to detemine what the bars should animate to.
local function infographic_bar_animation(dur, results_table, legend, testing_bool)
	testing_anim_id.bars = gre.animation_create(30, 1)

	for index, value in ipairs(DASHBOARD_CATEGORIES) do
		local upper
		local lower
		local category_result

		local target_lower
		local target_upper

		if value ~= "ecg" then
			upper = legend[value].upper_range
			lower = legend[value].lower_range

			target_lower = legend[value].target_range[1]
			target_upper = legend[value].target_range[2]

			category_result = test_results[value]
		elseif value == "ecg" then
			local systolic_table = legend[value].systolic
			local diastolic_table = legend[value].diastolic
			upper = (systolic_table.upper_range + diastolic_table.upper_range) / 2
			lower = (systolic_table.lower_range + diastolic_table.lower_range) / 2
			target_lower = (systolic_table.target_range[1] + diastolic_table.target_range[1]) / 2
			target_upper = (systolic_table.target_range[2] + diastolic_table.target_range[2]) / 2
			category_result = (test_results["systolic"] + test_results["diastolic"]) / 2
		end

		-- adding the range sections to the bars
		if infographic_bars_init == false then
			local range_start_percentage = score_utils:in_range(upper, lower, target_lower)
			local range_end_percentage = score_utils:in_range(upper, lower, target_upper)
			set_bar_ranges(value, BAR_GROUP_HEIGHT[value].arc_height, range_start_percentage, range_end_percentage)
		end

		local calculated_percentage = score_utils:in_range(upper, lower, category_result)

		add_bar_anim_step(
			value,
			BAR_GROUP_HEIGHT[value].arc_height,
			offset,
			calculated_percentage,
			dur,
			testing_bool
		)
		offset = offset + 200
	end

	if (infographic_bars_init == false) then
		gre.set_data({
			["infographic_layer.ecg_bar_group.ecg_result.grd_hidden"] = 0,
			["infographic_layer.spo2_bar_group.spo2_result.grd_hidden"] = 0,
			["infographic_layer.core_temp_bar_group.core_temperature_score.grd_hidden"] = 0,
			["infographic_layer.blood_sugar_bar_group.blood_sugar_result.grd_hidden"] = 0
		})
	end
	infographic_bars_init = true
	gre.animation_trigger(testing_anim_id.bars)
	offset = 50 -- reset offset
end



local diff_1 = BAR_GROUP_HEIGHT.ecg.arc_height - BAR_GROUP_HEIGHT.blood_sugar.arc_height
local diff_2 = BAR_GROUP_HEIGHT.spo2.arc_height - BAR_GROUP_HEIGHT.blood_sugar.arc_height
local diff_3 = BAR_GROUP_HEIGHT.core_temp.arc_height - BAR_GROUP_HEIGHT.blood_sugar.arc_height
local diff_4 = BAR_GROUP_HEIGHT.blood_sugar.arc_height - BAR_GROUP_HEIGHT.blood_sugar.arc_height
local bar_group_height_diff = { diff_1, diff_2, diff_3, diff_4 }

--- Displays the category score/100 on the infographic bars.
-- @function infographic_bar_animation_scores
-- These are needed by infographic_bar_animation_scores to do offset math so that
-- all the bars line up nicely when given a percentage
local function infographic_bar_animation_scores(dur, results_table, legend, testing_bool)
	testing_anim_id.bars = gre.animation_create(30, 1)

	if (infographic_bars_init == false) then
		gre.set_data({
			["infographic_layer.ecg_bar_group.fill_x_offset"] = (BAR_GROUP_HEIGHT.ecg.arc_height * -1) + diff_1,
			["infographic_layer.spo2_bar_group.fill_x_offset"] = (BAR_GROUP_HEIGHT.spo2.arc_height * -1) + diff_2,
			["infographic_layer.core_temp_bar_group.fill_x_offset"] = (BAR_GROUP_HEIGHT.core_temp.arc_height * -1) + diff_3,
			["infographic_layer.threshold_lines_group.grd_hidden"] = 0,
			["infographic_layer.marker_target_max_control.grd_hidden"] = 0,
			["infographic_layer.ecg_bar_group.ecg_score.grd_hidden"] = 0,
			["infographic_layer.spo2_bar_group.spo2_score.grd_hidden"] = 0,
			["infographic_layer.core_temp_bar_group.core_temperature_score.grd_hidden"] = 0,
			["infographic_layer.blood_sugar_bar_group.blood_sugar_score.grd_hidden"] = 0
		})
	end
	infographic_bars_init = true

	for index, value in ipairs(DASHBOARD_CATEGORIES) do
		local category_score = score_utils:get_category_score(value)
		local arc_height = BAR_GROUP_HEIGHT[value].arc_height - bar_group_height_diff[index]
		-- local duration = dur and dur or category_score * 20
		local duration = dur and dur or 1800

		add_bar_anim_step(
			value,
			arc_height,
			offset,
			category_score.score,
			duration,
			testing_bool
		)

		offset = offset + 200
		if (testing_bool == false) then
			gre.set_value("dashboard_results." .. value .. "_score_txt", category_score.score)
		elseif (testing_bool == true) then
			gre.set_value("dashboard_results." .. value .. "_score_txt", "000")
		end
	end

	gre.animation_trigger(testing_anim_id.bars)
	offset = 50 -- reset offset
end



local CIRCLE_OFFSET_X = 165
local function infographic_circle_animation(testing_bool, dur)
	local duration = dur and dur or 500

	testing_anim_id.circle = gre.animation_create(30, 1)

	local anim_data = {}
	anim_data["rate"] = "out_quint"
	anim_data["duration"] = duration
	anim_data["to"] = testing_bool == true and CIRCLE_OFFSET_X or 0
	anim_data["key"] = "infographic_layer.score_circle_group.center_R.grd_x"
	gre.animation_add_step(testing_anim_id.circle, anim_data)
	anim_data = {}

	anim_data["rate"] = "out_quint"
	anim_data["duration"] = duration
	anim_data["to"] = testing_bool == true and CIRCLE_OFFSET_X or 0
	anim_data["key"] = "infographic_layer.score_circle_group.center_fill.grd_width"
	gre.animation_add_step(testing_anim_id.circle, anim_data)
	anim_data = {}

	anim_data["rate"] = "linear"
	anim_data["duration"] = 150
	anim_data["offset"] = testing_bool == true and 50 or 200
	anim_data["to"] = testing_bool == true and 0 or 255
	anim_data["key"] = "infographic_layer.score_circle_group.center_control.health_score_txt_alpha"
	gre.animation_add_step(testing_anim_id.circle, anim_data)
	anim_data = {}

	anim_data["rate"] = "linear"
	anim_data["duration"] = 150
	anim_data["to"] = testing_bool == true and 255 or 0
	anim_data["offset"] = testing_bool == true and 200 or 50
	anim_data["key"] = "infographic_layer.score_circle_group.test_running_control.testing_txt_alpha"
	gre.animation_add_step(testing_anim_id.circle, anim_data)
	anim_data = {}

	gre.animation_trigger(testing_anim_id.circle)
end



local LINE_WIDTH = 372
local underline_anim_id = {}
local function category_underline_anim()
	if (type(underline_anim_id) ~= "table") then
		gre.animation_destroy(underline_anim_id)
		underline_anim_id = {}
	end
	underline_anim_id = gre.animation_create(30, 1)
	local anim_data = {}
	-- animate category underline on
	anim_data["rate"] = "out_quint"
	anim_data["duration"] = 750
	anim_data["from"] = 10
	anim_data["to"] = LINE_WIDTH
	anim_data["key"] = "result_windows_layer.category_group.results_underline.grd_width"
	gre.animation_add_step(underline_anim_id, anim_data)
	gre.animation_trigger(underline_anim_id, anim_data)
end



-- the default category to start the inforgraphic range on
-- options: ecg, spo2, core_temp, blood_sugar
local current_category = "ecg"
local function update_infographic_range(props)
	local category = props.category
	current_category = category
	local bar_path = props.bar_path
	local bar_vals = score_utils:in_bar(category, bar_path)
	gre.set_data({
		[bar_path .. ".range_start"] = bar_vals.range_start_val,
		[bar_path .. ".range_end"] = bar_vals.range_end_val,
		[bar_path .. ".pointer_pos"] = bar_vals.score_val,
	})
end



local PATH_TO_INFOGRAHIC_BAR = "infographic_layer.infographic_category.range_bar"
local TESTING_DURATION = 2000
local IDLE_DURATION = 6000
local updating_result = false
local vitals_test_timer_id = {}
local function trigger_dashboard_update()
	if updating_result == false then
		updating_result = true
		warning_icon_animation(true)
		format_test_results(TEST_RESULTS_BLANK, true)
		if (current_mode == "score_in_range") then
			infographic_bar_animation(nil, test_results, score_range_legend, true)
		elseif (current_mode == "category_score") then
			infographic_bar_animation_scores(nil, test_results, score_range_legend, true)
		end
		infographic_circle_animation(true)
		for i, v in ipairs(DASHBOARD_CATEGORIES) do
			gre.set_value("dashboard_results." .. v .."_message_txt", "---")
		end
		-- reset timer
		gre.timer_clear_timeout(vitals_test_timer_id)
		vitals_test_timer_id = {}
		vitals_test_timer_id = gre.timer_set_timeout(
			TESTING_DURATION,
			trigger_dashboard_update
		)
	elseif updating_result == true then
		updating_result = false
		test_results = get_test_results:generate_results(true)
		update_dashboard_results:set_date_time()
		format_test_results(test_results)
		update_infographic_range({
			category = current_category,
			bar_path = PATH_TO_INFOGRAHIC_BAR
		})
		update_health_score(test_results, score_range_legend)
		warning_icon_animation(false)
		if (current_mode == "score_in_range") then
			infographic_bar_animation(nil, test_results, score_range_legend, false)
		elseif (current_mode == "category_score") then
			infographic_bar_animation_scores(nil, test_results, score_range_legend, false)
		end
		infographic_circle_animation(false)

		-- reset timer
		gre.timer_clear_timeout(vitals_test_timer_id)
		vitals_test_timer_id = {}
		vitals_test_timer_id = gre.timer_set_timeout(
			IDLE_DURATION,
			trigger_dashboard_update
		)
	end
end



local function trigger_dashboard_timer()
	vitals_test_timer_id = gre.timer_set_timeout(IDLE_DURATION, trigger_dashboard_update)
end


-- TODO When this isn't triggered by a screen leave it's currently triggered by
-- pressing on the category_group layer, this should be replaced by a button
-- that visually displays the paused state.
local function toggle_testing(screen_leave_bool)
	-- check to see if there's a timer
	if (type(vitals_test_timer_id) == "userdata") then
		print("PAUSED") -- TODO replace this once there's a pause icon
		gre.timer_clear_timeout(vitals_test_timer_id)
		vitals_test_timer_id = {}
		-- Condition for if there's currently a test running and a pause is toggled
		if (updating_result == true) then
			updating_result = false
			-- Cancel and reset the bars animation
			gre.animation_destroy(testing_anim_id.bars)
			if (current_mode == "score_in_range") then
				infographic_bar_animation(0, test_results, score_range_legend, false)
			elseif (current_mode == "category_score") then
				infographic_bar_animation_scores(0, test_results, score_range_legend, false)
			end
			-- Cancel and reset the circle animation
			gre.animation_destroy(testing_anim_id.circle)
			infographic_circle_animation(false, 0)
			-- Return the results to the old ones
			format_test_results(test_results)
		end
	else
		if (screen_leave_bool ~= true) then
			print("UNPAUSED")
			trigger_dashboard_timer()
		end
	end
end


local initial_setup = false
local function setup_funcs()
	if (initial_setup == false) then
		gre.animation_trigger(
			"dash_" .. current_category .. "_toggle",
			{ context = "result_windows_layer." .. current_category .. "_group" }
		)
		update_dashboard_results:set_date_time()
		initial_setup = true
	end
	
	updating_result = false
	update_infographic_range({
		category = current_category,
		bar_path = PATH_TO_INFOGRAHIC_BAR
	})
	update_health_score(test_results, score_range_legend)
	warning_icon_animation(false)
	
	if (current_mode == "score_in_range") then
		infographic_bar_animation(0, test_results, score_range_legend, false)
	elseif (current_mode == "category_score") then
		infographic_bar_animation_scores(0, test_results, score_range_legend, false)
	end
end


local function init_CB(mapargs)
	format_test_results(test_results, false)
	setup_funcs()
	trigger_dashboard_timer()
end


local function dashboard_hide_CB()
	toggle_testing(true)
end

return {
	init_CB = init_CB,
	update_infographic_range = update_infographic_range,
	dashboard_hide_CB = dashboard_hide_CB,
	category_underline_anim = category_underline_anim,
	toggle_testing = toggle_testing
}
