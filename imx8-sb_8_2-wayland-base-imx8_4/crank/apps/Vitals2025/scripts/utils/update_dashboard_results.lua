local update_dashboard_results = {}

--- Updates the test results on the dashboard.
-- @param self
-- @param key The category name (ecg, core_temp, etc.)
-- @param value The test result value to update to.
function update_dashboard_results:set_test_result_data(key, value)
	if key == "core_temp" then
		local core_temp_int = string.sub(value, 1, 2)
		local core_temp_dec = string.sub(value, -2)
		local layer_root = "result_windows_layer.core_temp_group.temperature_value."
		
		gre.set_data({
			[layer_root .. "int_txt"] = core_temp_int,
			[layer_root .. "dec_txt"] = core_temp_dec,
			[layer_root .. "dec_x"] = string.sub(core_temp_int, 2, 2) == "1" and 75 or 85,
			["dashboard_results." .. key .. "_result_txt"] = value,
			["dashboard_results." .. key .. "_rounded_txt"] = core_temp_int
		})
	elseif key == "blood_sugar" then
		local blood_sugar_int = string.match(value,"^(.-)%.")
		local blood_sugar_dec = "." .. string.match(value,"%.(.*)") .. "%"
		local layer_root = "result_windows_layer.blood_sugar_group.blood_sugar_value."
		local dec_spacing = #blood_sugar_int == 2 and 84 or 42
		
		gre.set_data({
			[layer_root .. "int_txt"] = blood_sugar_int,
			[layer_root .. "dec_txt"] = blood_sugar_dec,
			[layer_root .. "dec_x"] = dec_spacing,
			["dashboard_results." .. key .. "_result_txt"] = value,
			["dashboard_results." .. key .. "_rounded_txt"] = blood_sugar_int
		})
	elseif key == "ecg" then
		local systolic = string.match(value,"^(.-)/")
		local diastolic = string.match(value,"/(.*)")

		gre.set_data({
			["dashboard_results." .. key .. "_result_txt"] = value,
			["dashboard_results." .. key .. "_systolic_result_txt"] = systolic,
			["dashboard_results." .. key .. "_diastolic_result_txt"] = diastolic,
		})
	elseif key == "spo2" then
		local x_offset = 0
		if (#(tostring(value)) > 2) then
			x_offset = 38
		end
		gre.set_data({
			["result_windows_layer.spo2_group.icn_spo2.icn_x"] = x_offset,
			["dashboard_results." .. key .. "_result_txt"] = value
		})
	else
		gre.set_data({
			["dashboard_results." .. key .. "_result_txt"] = value
		})
	end
end

--- Sets the infographic time to the current time.
function update_dashboard_results:set_date_time()
	local day = os.date("%d")
	local month = os.date("%m")
	local year = os.date("%y")

	local hour = os.date("%H")
	local min = os.date("%M")
	
	local date_str = day .. " / " .. month .. " / " .. year
	local time_str = hour .. ":" .. min
	
	gre.set_data({
		["infographic_layer.infographic_category.label_date.dashboard_date_time_txt"] = date_str .. "\n" .. time_str
	})
end

return update_dashboard_results
