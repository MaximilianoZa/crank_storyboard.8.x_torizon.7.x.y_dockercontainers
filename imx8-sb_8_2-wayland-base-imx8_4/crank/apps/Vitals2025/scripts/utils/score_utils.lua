local score_range_legend = require('utils.score_legend')

local get_test_results = require('utils.get_test_results')
local test_results = get_test_results:generate_results(true)

--- Return the current score and range data from the ECG category
--- @function get_ecg_data
local function get_ecg_data()
    local systolic_table = score_range_legend["ecg"]["systolic"]
    local diastolic_table = score_range_legend["ecg"]["diastolic"]
    return {
		score = (test_results.systolic + test_results.diastolic) / 2,
		lower_range = (systolic_table.lower_range + diastolic_table.lower_range) / 2,
		upper_range = (systolic_table.upper_range + diastolic_table.upper_range) / 2,
		target_lower_range = (systolic_table.target_range[1] + diastolic_table.target_range[1]) / 2,
		target_upper_range = (systolic_table.target_range[2] + diastolic_table.target_range[2]) / 2,
    }
end

--- Return the current score and range data from a given category
--- @function get_category_data
--- @param category string the category to search for
local function get_category_data(category)
    if(category == "ecg") then
        return get_ecg_data()
    end

    return {
        score = test_results[category],
		lower_range = score_range_legend[category].lower_range,
		upper_range = score_range_legend[category].upper_range,
		target_lower_range = score_range_legend[category].target_range[1],
		target_upper_range = score_range_legend[category].target_range[2],
    }
end

local score_utils = {}

--- Translates and range and score into a scaled range
--- @function in_range
--- @param upper number the upper range
--- @param lower number the lower range
--- @param result number the actual result
--- @return number scaled_value
function score_utils:in_range(upper, lower, result)
    local percentage = (result - lower) / (upper - lower)
    return (100 * percentage)
end


--- Get the values to plot a range graph on a bar chart
--- @function score_utils:get_bar_range
--- @param category string the category to search for ranges
--- @param bar_path string the GDE path to bar chart
--- @return table values the bar chart values
function score_utils:in_bar(category, bar_path)
    local bar_height = gre.get_value(string.format("%s.grd_height", bar_path))
    local category_data = get_category_data(category)
	 
	local score_percentage = self:in_range(category_data.upper_range, category_data.lower_range, category_data.score)
	local start_percentage = self:in_range(category_data.upper_range, category_data.lower_range, category_data.target_lower_range)
	local end_percentage = self:in_range(category_data.upper_range, category_data.lower_range, category_data.target_upper_range)
	 
	local score_val = bar_height * (score_percentage / 100)
	local range_start_val = bar_height * (start_percentage / 100)
	local range_end_val = (bar_height * (end_percentage / 100)) - range_start_val
	
	return {
		score_val = score_val,
		range_start_val = range_start_val,
		range_end_val = range_end_val
	}
end

--- Return a score (out of 100) based on the active test results
--- @function score_utils:get_category_score
--- @param category string the category to search results for
--- @return table {score, state, msg}. -1=under, 0=in range, 1=over
function score_utils:get_category_score(category)
    local category_data = get_category_data(category)
    local score_tbl = {score = 0, state = 0, msg = ""}

    if (category_data.score >= category_data.target_lower_range and category_data.score <= category_data.target_upper_range) then
        score_tbl.score = 100
        score_tbl.state = 0
        score_tbl.msg = "Within Target Range"
	elseif (category_data.score < category_data.target_lower_range) then
		local scaled_score = self:in_range(category_data.target_lower_range, category_data.lower_range, category_data.score)
        score_tbl.score = math.floor(scaled_score)
        score_tbl.state = -1
        score_tbl.msg = "Under Target Range"
	elseif (category_data.score > category_data.target_upper_range) then
		local scaled_score = score_utils:in_range(category_data.target_upper_range, category_data.upper_range, category_data.score)
        score_tbl.score = math.floor(scaled_score)
        score_tbl.state = 1
        score_tbl.msg = "Over Target Range"
	end

    return score_tbl
end

return score_utils