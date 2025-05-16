local STEP_OFFSET = 500
local MAX_STEPS = 3

local TABLE_PATH = "pulse_setup_layer.steps_display.steps_table"
local PAGINATION_PATH = "pulse_setup_layer.steps_display.steps_pagination"

local PG_ON_IMG = "images/pg_on.png"
local PG_OFF_IMG = "images/pg_off.png"

local pulse_setup = {}
pulse_setup.active_step = 1
pulse_setup.pressed = false
pulse_setup.scroll_anim = nil

--- Reset the pulse setup back to default view
--- @function pulse_setup:reset
function pulse_setup:reset()
    local offset_path = string.format("%s.grd_xoffset", TABLE_PATH)
    gre.set_value(offset_path, 0)
end

--- Create and trigger the sliding animation
--- @function pulse_setup:animate_step
function pulse_setup:animate_step(offset)
    if(self.scroll_anim) then
        gre.animation_destroy(self.scroll_anim)
        self.scroll_anim = nil
    end

    local offset_path = string.format("%s.grd_xoffset", TABLE_PATH)
    local cur_offset = gre.get_value(offset_path)

    self.scroll_anim = gre.animation_create(30, 1)
    gre.animation_add_step(self.scroll_anim, {
        key = offset_path,
        from = cur_offset,
        to = offset,
        rate = "out_quint",
        duration = 500
    })
    gre.animation_trigger(self.scroll_anim)
end

--- Show the active step
--- @function pulse_setup:show_step
function pulse_setup:show_step()
    -- Calculate table offset
    local offset = (self.active_step * STEP_OFFSET) - STEP_OFFSET
    self:animate_step(-offset)

    -- Set pagination
    local data = {}
    for i=1, MAX_STEPS do
        local path = string.format("%s.step_%d_img", PAGINATION_PATH, i)
        local img = (self.active_step == i) and PG_ON_IMG or PG_OFF_IMG
        data[path] = img
    end
    gre.set_data(data)
end

--- A gesture.left event has occured
--- @function pulse_setup:gesture_left
function pulse_setup:gesture_left()
    if(not self.pressed) then return end
    if(self.active_step == MAX_STEPS) then
        return
    end

    self.active_step = self.active_step + 1
    self:show_step()
end

--- A gesture.right event has occured
--- @function pulse_setup:gesture_right
function pulse_setup:gesture_right()
    if(not self.pressed) then return end
    if(self.active_step == 1) then
        return
    end

    self.active_step = self.active_step - 1
    self:show_step()
end

--- A press event has occured
--- @function pulse_setup:press
function pulse_setup:press()
    self.pressed = true
end

--- An outbound event has occured
--- @function pulse_setup:outbound
function pulse_setup:outbound()
    self.pressed = false
end

return pulse_setup