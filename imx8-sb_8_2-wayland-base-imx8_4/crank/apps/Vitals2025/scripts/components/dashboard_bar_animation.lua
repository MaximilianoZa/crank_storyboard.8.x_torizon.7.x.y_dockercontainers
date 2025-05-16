-- [] Need animation id
-- [x] Need dashboard categories
-- [] Test results

local score_utils = require('utils.score_utils')

local DASHBOARD_CATEGORIES = { "ecg", "spo2", "core_temp", "blood_sugar" }
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

local anim_id

local function animation_generator(group_key, arc_height, offset_val, score_percentage, dur, testing_bool)
	local test_percentage = score_percentage
	local path_to_group = "infographic_layer." .. group_key .. "_bar_group."
	local fill_max = arc_height + 183 -- 183 is the length of the fill
	local arc_max = 180 + (183  / (arc_height / 180))

	-- set the fill based on percentage
	local ecg_fill_width = fill_max * (test_percentage / 100)
	local ecg_arc_angle = ecg_fill_width / (fill_max / arc_max)

	local duration = dur and dur or 1500
	
	local anim_data = {}
	anim_data["rate"] = "out_quint"
	anim_data["duration"] = duration
	anim_data["to"] = testing_bool == false and ecg_fill_width or 0
	anim_data["offset"] = dur ~= nil and 0 or offset_val
	anim_data["key"] = path_to_group .. "fill"
	gre.animation_add_step(testing_anim_id.bars, anim_data)
	anim_data = {}

	anim_data["rate"] = "out_quint"
	anim_data["duration"] = duration
	anim_data["to"] = testing_bool == false and ecg_arc_angle or 0
	anim_data["offset"] = dur ~= nil and 0 or offset_val
	anim_data["key"] = path_to_group .. "arc"
	gre.animation_add_step(testing_anim_id.bars, anim_data)
	anim_data = {}
end

 -- sets the gray segments on the bars showing the target ranges
local function set_bar_ranges(group_key, arc_height, start_percentage, end_percentage)
	local path_to_group = "infographic_layer." .. group_key .. "_bar_group."
	local fill_max = arc_height + 183 -- 183 is the length of the fill
	local arc_max = 180 + (183  / (arc_height / 180))
	
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

local infographic_bar_anim = {}

--- Animates the curved bars.
-- Create animations for each bar category then triggers them.
-- @param dur Duration, if 0 the update is immediate.
-- @param results_table Table of results to iterate over.
-- @param legend Legend that's used to determine how the current score is displayed.
-- @param testing_bool Bool used to detemine what the bars should animate to.
function infographic_bar_anim:result_in_range(dur, results_table, legend, testing_bool)
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
		
		animation_generator(
			value,
			BAR_GROUP_HEIGHT[value].arc_height,
			offset,
			calculated_percentage,
			dur,
			testing_bool
		)
		offset = offset + 200
	end
	
	infographic_bars_init = true 
	gre.animation_trigger(testing_anim_id.bars)
	offset = 50      -- reset offset
end

local diff_1 = 486 - 248 -- 238
local diff_2 = 408 - 248 -- 160
local diff_3 = 326 - 248 -- 78
local diff_4 = 0
local bar_group_height_diff = {diff_1, diff_2, diff_3, diff_4}

function infographic_bar_anim:result_score(dur, results_table, legend, testing_bool, anim_id)
	testing_anim_id.bars = gre.animation_create(30, 1)
	
	if (infographic_bars_init == false) then
		gre.set_data({
			["infographic_layer.ecg_bar_group.fill_x_offset"] =  -486 + diff_1,
			["infographic_layer.spo2_bar_group.fill_x_offset"] =  -408 + diff_2,
			["infographic_layer.core_temp_bar_group.fill_x_offset"] =  -326 + diff_3,
			["infographic_layer.threshold_lines_group.grd_hidden"] = 0,
			["infographic_layer.marker_target_max_control.grd_hidden"] = 0
		})
	end
	infographic_bars_init = true
	
	for index, value in ipairs(DASHBOARD_CATEGORIES) do
		local category_score = score_utils:get_category_score(value)
		local arc_height = BAR_GROUP_HEIGHT[value].arc_height - bar_group_height_diff[index]
		animation_generator(
			value,
			arc_height,
			offset,
			category_score,
			dur,
			testing_bool
		)
		offset = offset + 200
	end
	
	gre.animation_trigger(testing_anim_id.bars)
	offset = 50 -- reset offset
end

return infographic_bar_anim
