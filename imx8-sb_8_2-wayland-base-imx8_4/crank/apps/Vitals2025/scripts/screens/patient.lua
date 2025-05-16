local PATHS = {
    details_layer = "patient_sc.patient_details_layer",
    summary_layer = "patient_sc.patient_summary_layer",
    schedule_layer = "patient_sc.patient_schedule_layer",
}

local patient = {}

--- Reset the patient screen
--- @function patient:reset
function patient:reset()
    gre.set_data({
        [string.format("%s.grd_yoffset", PATHS.details_layer)] = 0,
        [string.format("%s.grd_yoffset", PATHS.summary_layer)] = 0,
        [string.format("%s.grd_yoffset", PATHS.schedule_layer)] = 0,
    })
end

--- Initialize the patient screen
--- @function patient:init
function patient:init()
    self:reset()
end

--- The patient screen has been hidden
--- @function patient:hide
function patient:hide()
    self:reset()
end

return patient