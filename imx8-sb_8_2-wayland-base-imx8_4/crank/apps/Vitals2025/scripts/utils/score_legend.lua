local score_range_legend = {
	["ecg"] = {
		["systolic"] = {
			["upper_range"] = 180,
			["lower_range"] = 80,
			["target_range"] = { 90, 120 }

		},
		["diastolic"] = {
			["upper_range"] = 99,
			["lower_range"] = 40,
			["target_range"] = { 60, 80 }
		}
	},
	["pleth"] = {
		["oxygen"] = {
			["upper_range"] = 99,
			["lower_range"] = 95
		},
		["heart_rate"] = {
			["upper_range"] = 99,
			["lower_range"] = 60
		},
		["respiration"] = {
			["upper_range"] = 20,
			["lower_range"] = 12
		}
	},
	["blood_lipids"] = {
		["blood_tc"] = {
			["upper_range"] = 250,
			["lower_range"] = 150,
		},
		["blood_tg"] = {
			["upper_range"] = 220,
			["lower_range"] = 130,
		},
		["blood_ldl"] = {
			["upper_range"] = 170,
			["lower_range"] = 120,
		},
		["blood_hdl"] = {
			["upper_range"] = 70,
			["lower_range"] = 30,
		},
	},
	["spo2"] = {
		["upper_range"] = 100,
		["lower_range"] = 80,
		["target_range"] = { 95, 100 }
	},
	["core_temp"] = {
		["upper_range"] = 38.5,
		["lower_range"] = 35.5,
		["target_range"] = { 36.5, 37.5 }
	},
	["blood_sugar"] = {
		["upper_range"] = 7,
		["lower_range"] = 3,
		["target_range"] = { 3.9, 5.6 }
	},
	["heart_rate_resting"] = {
		["upper_range"] = 64,
		["lower_range"] = 35,
		["target_range"] = {45, 75}
	}
}

return score_range_legend