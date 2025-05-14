local hold_timer = nil
local repeat_timer = nil

-- @params gre#context mapargs
function cb_minus_press(mapargs)
    hold_timer = gre.timer_set_timeout(500, minus_repeat)
end

function minus_repeat()
    hold_timer = nil
    repeat_timer = gre.timer_set_interval(250, cb_temp_down)
end

-- @params gre#context mapargs
function cb_plus_press(mapargs)
    hold_timer = gre.timer_set_timeout(500, plus_repeat)
end

function plus_repeat()
    hold_timer = nil
    repeat_timer = gre.timer_set_interval(250, cb_temp_up)
end

function clear_timers()
    if hold_timer then
        gre.timer_clear_timeout(hold_timer)
        hold_timer = nil
    end
    
    if repeat_timer then
        gre.timer_clear_interval(repeat_timer)
        repeat_timer = nil
    end
end

