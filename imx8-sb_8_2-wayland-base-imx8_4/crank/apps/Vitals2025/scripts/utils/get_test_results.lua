local score_range_legend = require('utils.score_legend')

local divide_by_ten = {
	core_temp = true,
	blood_sugar = true,
	blood_tc = true,
	blood_tg = true,
	blood_ldl = true,
	blood_hdl = true,
}

local get_test_results = {}
local test_results = {}

local recursion_keys = {
	["ecg"] = true,
	["pleth"] = true,
	["blood_lipids"] = true,
}

local function build_test_results(score_table)
	for key, value in pairs(score_table) do
		if (recursion_keys[key]) then
			build_test_results(value)
		 else
			local upper_range, lower_range, divider
			if (divide_by_ten[key] == true) then
				upper_range = value.upper_range * 10
				lower_range = value.lower_range * 10
				divider = 10
			else
				upper_range = value.upper_range
				lower_range = value.lower_range
				divider = 1
			end
			test_results[key] = (math.random(lower_range, upper_range)) / divider
		 end
	end
end

--- Get the current test results or generate new ones and return those.
-- @function generate_results
-- @param randomize bool generates new test results, false returns the current results.
-- @return A table of test results.
function get_test_results:generate_results(randomize)
	math.randomseed(os.time())
	if(randomize) then
		build_test_results(score_range_legend)
	end
	return test_results
end

get_test_results:generate_results(true)

return get_test_results