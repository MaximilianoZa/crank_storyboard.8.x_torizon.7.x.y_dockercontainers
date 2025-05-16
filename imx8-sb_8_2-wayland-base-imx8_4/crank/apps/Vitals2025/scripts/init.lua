MCU_MODE = false

---------------
-- UTILITIES --
---------------

-- invoke
local invoke = require('utils.invoke')
function cb_invoke_module(mapargs)
    local module = mapargs.module
    local method = mapargs.method
    invoke.module(module, method, mapargs)
end

-- animation easing
local easing_library = require('utils.animation_easing')
gre.animation_create_tween("out_quint", easing_library.out_quint)
gre.animation_create_tween("in_quint", easing_library.in_quint)
gre.animation_create_tween("out_in_quint", easing_library.out_in_quint)

-------------
-- MODULES --
-------------

local navigation = require('components.navigation')
navigation:init()

-------------
-- SCREENS --
-------------

-- dashboard screen
local dashboard = require('screens.dashboard')
dashboard_init_CB = dashboard.init_CB
dashboard_hide_CB = dashboard.dashboard_hide_CB
toggle_dash_category_CB = dashboard.update_infographic_range
category_underline_anim_CB = dashboard.category_underline_anim
toggle_testing_CB = dashboard.toggle_testing

-- ecg screen
local ecg = require('screens.ecg')
ecg_sc_init_CB = ecg.init_CB
ecg_sc_leave_CB = ecg.screen_leave_CB
init_ecg_line_CB = ecg.init_ecg_line_CB

local ecg2 = require('screens.ecg2')
local spo2 = require('screens.spo2')
local temperature = require('screens.temperature')
local insulin = require('screens.insulin')
local patient = require('screens.patient')

function APP_INIT()
    ecg2:init()
    spo2:init()
    temperature:init()
    insulin:init()
    patient:init()
end