local table_utils = require('utils.table_utils')

local DEFAULT_IDX = 3 -- Dashboard
local GESTURE_OFFSET = 167 -- How much to move the nav bar
local NAV_Y = 590

local MAIN_TOGGLE_SIZE = 78
local FIRST_TIER_TOGGLE_SIZE = MAIN_TOGGLE_SIZE * 0.7
local SECOND_TIER_TOGGLE_SIZE = FIRST_TIER_TOGGLE_SIZE * 0.7
local OUT_OF_SCOPE_TOGGLE_SIZE = SECOND_TIER_TOGGLE_SIZE * 0.7

local NAV_ITEMS = {
    "icn_spo2",
    "icn_ecg",
    "icn_dashboard",
    "icn_temperature",
    "icn_insulin",
    "icn_patient"
}
  
local SCREEN_NAMES = {
    "spo2_sc",
    "ecg_sc",
    "dashboard_results",
    "temperature_sc",
    "insulin_sc",
    "patient_sc"
}

--- Get the icon index from control name
--- @function get_icon_index
--- @param ctrl string the icon to check
local function get_icon_index(ctrl)
    for key, value in pairs(NAV_ITEMS) do
        if(value == ctrl) then
            return key
        end
    end
end

--- Create and trigger an icon animation
--- @function create_icon_animation
--- @param key string the icon key to animate
--- @param end_val number the ending value for property
--- @param property string the key property to animate
--- @param alpha? boolean is the key an alpha value
local function create_icon_animation(key, end_val, property, alpha)
    local anim_id = gre.animation_create(30, 1)
    local anim_data = {}
    anim_data["rate"] = "out_quint"
    anim_data["duration"] = 400
    anim_data["to"] = end_val
    anim_data["key"] = string.format("%s.%s", key, property)
    gre.animation_add_step(anim_id, anim_data)
    gre.animation_trigger(anim_id)
end

--- Animate the main toggle
--- @function main_toggle
--- @param control_name string the control name
local function main_toggle(control_name)
    local control_key = string.format("navigation_layer.%s", control_name)
    create_icon_animation(control_key, 255, "icn_selected_alpha", true)
    create_icon_animation(control_key, MAIN_TOGGLE_SIZE, "grd_width")
end

--- Animate a first tier toggle
--- @function first_tier_toggle
--- @param control_name string the control name
local function first_tier_toggle(control_name)
    local control_key = string.format("navigation_layer.%s", control_name)
    create_icon_animation(control_key, 150, "icn_alpha", true)
    create_icon_animation(control_key, 0, "icn_selected_alpha", true)
    create_icon_animation(control_key, FIRST_TIER_TOGGLE_SIZE, "grd_width")
end

--- Animate a second tier toggle
--- @function second_tier_toggle
--- @param control_name string the control name
local function second_tier_toggle(control_name)
    local control_key = string.format("navigation_layer.%s", control_name)
    create_icon_animation(control_key, 255, "icn_alpha", true)
    create_icon_animation(control_key, 125, "icn_alpha", true)
    create_icon_animation(control_key, 0, "icn_selected_alpha", true)
    create_icon_animation(control_key, SECOND_TIER_TOGGLE_SIZE, "grd_width")
end

--- Animate an out of scope toggle
--- @function out_of_scope_toggle
--- @param control_name string the control name
local function out_of_scope_toggle(control_name)
    local control_key = "navigation_layer." .. control_name
    create_icon_animation(control_key, 0, "icn_alpha", true)
    create_icon_animation(control_key, 0, "icn_selected_alpha", true)
    create_icon_animation(control_key, OUT_OF_SCOPE_TOGGLE_SIZE, "grd_width")
end

local navigation = {}
navigation.index = DEFAULT_IDX
navigation.in_bounds = false
navigation.offset = 0
navigation.scroll_anim = nil

--- Animate the navigation icons
--- @function navigation:animate_icons
function navigation:animate_icons()
    for i=1, #NAV_ITEMS do
        local icon_name = NAV_ITEMS[i]
		if i == self.index then
			main_toggle(icon_name)
		elseif i == (self.index + 1) or i == (self.index - 1) then
			first_tier_toggle(icon_name)
		elseif i == (self.index + 2) or i == (self.index - 2) then
			second_tier_toggle(icon_name)
		elseif (i > (self.index + 2)) or (i < (self.index + 2)) then
			out_of_scope_toggle(icon_name)
		end
    end
end

--- Scroll the navigation bar
--- @function navigation:scroll
--- @param direction string the direction to scroll
--- @param end_val number the X value to end at
function navigation:scroll(direction, end_val)
    if(self.scroll_anim) then
        gre.animation_destroy(self.scroll_anim)
        self.scroll_anim = nil
    end

    -- Set the screen
    local screen = SCREEN_NAMES[self.index]
    gre.set_data({
        transition_direction = direction,
        transition_screen = screen
    })
    gre.send_event("change_screen")

    -- Animate the scrolling
    self.scroll_anim = gre.animation_create(30, 1)
    gre.animation_add_step(self.scroll_anim, {
        key = "${screen:navigation_layer.grd_xoffset}",
        rate = "out_quint",
        duration = 600,
        from = self.offset,
        to = end_val
    })
    gre.animation_trigger(self.scroll_anim)

    -- Animate the icons
    self:animate_icons()
end

--- A gesture.left event has occured
--- @function navigation:gesture_left
function navigation:gesture_left()
    if(not self.in_bounds) then return end
    if(self.index >= #NAV_ITEMS) then
        return
    end

    local new_offset = (self.offset - GESTURE_OFFSET)
    self.index = self.index + 1
    self:scroll("right", new_offset)
    self.offset = new_offset
end

--- A gesture.right event has occured
--- @function navigation:gesture_right
function navigation:gesture_right()
    if(not self.in_bounds) then return end
    if(self.index == 1) then
        return
    end

    local new_offset = (self.offset + GESTURE_OFFSET)
    self.index = self.index - 1
    self:scroll("left", new_offset)
    self.offset = new_offset
end

--- A navigation icon has been touched
--- @function navigation:icon_touch
--- @param mapargs table the args from touch
function navigation:icon_touch(mapargs)
    -- Get which control was touch and its index
    local split = table_utils:split_string(mapargs.context_control, ".")
    local ctrl = split[2]
    local index = get_icon_index(ctrl)

    -- Process the scroll
    local dir = index > self.index and "right" or "left"
    local diff = index - self.index
    local offset = (GESTURE_OFFSET * diff)
    local new_offset = (self.offset - offset)

    self.index = index
    self:scroll(dir, new_offset)
    self.offset = new_offset
end

--- A press event has occured
--- @function navigation:press
function navigation:press()
    self.in_bounds = true
end

--- A outbound event has occured
--- @function navigation:outbound
function navigation:outbound()
    self.in_bounds = false
end

--- Initialize the navigation
--- @function navigation:init
function navigation:init()
    self:animate_icons()
end

--- Update the offset in navigation
--- @function navigation:update_offset
--- @param screen string the screen that has been navigated to
function navigation:update_offset(screen)
    local path = string.format("%s.navigation_layer.grd_xoffset", screen)
    gre.set_value(path, self.offset)
end

--- Update the navbar offset whenever a new screen is shown
gre.add_event_listener("gre.screenshow.pre", function(mapargs)
    navigation:update_offset(mapargs.context_screen)
end)

--- Whenever the screen is pressed, check if it was below the nav bar Y val.
--- The nav bar takes up the remaining vertical space so we can presume that's what they pressed on.
gre.add_event_listener("gre.press", function(mapargs)
    local press_y = mapargs.context_event_data.y

    if(press_y >= NAV_Y) then
        navigation:press()
    else
        navigation:outbound()
    end
end)

return navigation