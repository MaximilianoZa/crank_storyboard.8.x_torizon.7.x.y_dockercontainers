local toggle_state = {} -- table used to track state for all toggles

function CBToggleControl(mapargs)
  local control = mapargs.context_control
  
  ---@field gre#animationdata
  local anim_data = {}
  
  -- triggering an animation with context will allow context variables to be resolved (i.e. ${control:slider_x})
  anim_data["context"] = control
  
  -- triggering slider_on and slider_off with the same id makes these animations mutually exclusive for this control
  -- which means only slider_on or slider_off can run at once
  anim_data["id"] = control 
  
  if (toggle_state[control] == nil) then
    -- if it doesn't exist yet create the toggle and set it to off
    toggle_state[control] = false
  end
  toggle_state[control] = not toggle_state[control]
  
  local state = gre.animation_get_state("settings_toggle", anim_data)
  
  --trigger the animation from the current progress, just reverse it
  -- When running forwards, we do not want to cleanup, so that we can remember how to go backwards again.
  -- When running backwards, we can cleanup because an animation always knows how to run forwards.
  anim_data.progress = state.progress
  anim_data.reverse = not toggle_state[control]
  anim_data.cleanup = anim_data.reverse
  
  gre.animation_trigger("settings_toggle", anim_data)
end
