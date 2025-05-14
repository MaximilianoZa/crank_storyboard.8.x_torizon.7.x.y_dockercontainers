--- thermostat temperatures
local current_temp = 18
local HIGHEST_TEMP = 40
local LOWEST_TEMP = -20

--- Cooling or heating mode enum
local MODE_OFF = 0
local MODE_COOLING = 1
local MODE_HEATING = 2

--- Fan state enum
local FAN_INIT = 0
local FAN_AUTO = 1
local FAN_ON = 2
local FAN_OFF = 3

--- Passcode
local PASSCODE_LENGTH = 4
local PASSCODE = '1234'

local pwd = ''

local fan_interval_timer = nil

--- Temperature unit for the whole app
local g_unit = 'C'
local UNIT_CELSIUS = 'C'
local UNIT_FAHRENHEIT = 'F'

--- Settings screen slide start point offset
local TRACK_START_X = 25
local active_slider = nil

local weather_temp_paths = {
  'weather_layer.weather_day_control.temp_text',
  'forecast_layer.day1_control.text',
  'forecast_layer.day2_control.text',
  'forecast_layer.day3_control.text',
  'current_layer.temp_feel_control.text',
  'current_layer.temp_high_control.text',
  'current_layer.temp_low_control.text',
}


---------------------------------------------------------
-- Local functions

--- Convert temperature value from celsius to fahrenheit
-- @param temp Integer value in celsius
local function celsius_to_fahrenheit(temp)
  return math.floor((temp * 9 / 5) + 32 + 0.5)
end

--- Convert temperature value from fahrenheit to celsius
-- @param temp Integer value in fahrenheit
local function fahrenheit_to_celsius(temp)
  return math.floor((temp - 32) * 5 / 9 + 0.5)
end

--- Stops looping fan animation on thermostat screen
local function clear_fan_animation()
  if fan_interval_timer ~= nil then
      gre.timer_clear_interval(fan_interval_timer)
      fan_interval_timer = nil
  end
  
  gre.animation_stop('fan_on_thermostat')
end

local function trigger_fan()
  gre.animation_trigger('fan_spin_thermostat')
end

--- Updates fan indicator on thermostat screen
-- @param state Represents new fan state in number form, 0,1,2,3
local function update_fan_state(state)
  clear_fan_animation()
  
  local alpha = 0
  local text = ''
  local data = {}
  
  if state == FAN_AUTO or state == FAN_INIT then 
    fan_interval_timer = gre.timer_set_interval(5000, trigger_fan)
    
    alpha = 255
    text = 'Auto'
    state = FAN_AUTO
  elseif state == FAN_ON then
    gre.animation_trigger('fan_on_thermostat')
    alpha = 255
    text = 'On'
    state = FAN_ON
  elseif state == FAN_OFF then
    alpha = 75
    text = 'Off'
    state = FAN_OFF
  end
  
  data = {
      ['thermostat_layer.fan_control.fan_alpha'] = alpha,
      ['thermostat_layer.fan_control.fan_text'] = text,
      ['thermostat_layer.fan_control.fan_state'] = state
  }
  
  gre.set_data(data)
end

--- Convert given temperature value to match system temperature units
-- @param num temp
local function convert_temperature(temp)
  if (g_unit == UNIT_FAHRENHEIT) then
      return celsius_to_fahrenheit(temp)
  else        
      return fahrenheit_to_celsius(temp)
  end
end

--- Updates temperature values on the weather screen to reflect the new temperature unit 
local function convert_weather_temps()
  local data = {}
  local degree = ''
  
  for i=1,#weather_temp_paths do 
    local old_temp = gre.get_value(weather_temp_paths[i])
    
    if string.find(old_temp,'º') then 
      degree = 'º'
      old_temp = string.gsub(old_temp,'º','')
    end
    
    old_temp = tonumber(old_temp)
    
    local new_temp = convert_temperature(old_temp)
    data[weather_temp_paths[i]] = string.format('%d%s',new_temp,degree)
  end
 
  data['temperature_unit'] = string.format('º%s', g_unit)
  gre.set_data(data)
end

--- Updates temperature values on the thermostat screen to reflect the new temperature unit 
local function convert_thermostat_temps()
  local unit_text = ''
  local temp = ''
  
  current_temp = convert_temperature(current_temp)
  HIGHEST_TEMP = convert_temperature(HIGHEST_TEMP)
  LOWEST_TEMP = convert_temperature(LOWEST_TEMP)
  
  unit_text = g_unit == UNIT_FAHRENHEIT and 'Fahrenheit' or 'Celsius'

  temp = string.format('%s˚', current_temp)
  
  local data = {
      ['thermostat_layer.temperature_unit.unit_text'] = unit_text,
      ['thermostat_layer.temp_val.temp'] = temp
  }
  
  gre.set_data(data)
end

--- Move slider marker based on the press and motion event 
-- @param control Path to slider control
-- @param press_x X position of user interaction on slider control
local function calculate_slider_position(control, press_x)
  -- Get press event x position
  local attrs = gre.get_control_attrs(control, 'x', 'width')
  -- Get relative x position
  local new_x = press_x - attrs.x

  -- Handle edge case with TRACK_START_X
  if (new_x <= TRACK_START_X) then
      new_x = TRACK_START_X
  elseif new_x >= attrs.width - TRACK_START_X then
      new_x = attrs.width - TRACK_START_X
  end

  gre.set_value(control..'.offset_x', new_x - TRACK_START_X / 2)
  gre.set_value(control..'.hightlight_offset_x', new_x - TRACK_START_X)
end

--- Trigger screen transition 
-- @param target_screen string New screen to transition to
local function screen_transition(target_screen)
  gre.set_value('target_sc', target_screen)
  gre.send_event('screen_navigate')
end

--- Close info layer
-- @param screen string Current screen
local function hide_info_layer(screen)
  gre.animation_trigger('slide_out_context', {context=screen}) 
end

---------------------------------------------------------------------
-- Callbacks

--- Thermostat Screen: Increase temperature
-- @param gre#context mapargs
function cb_temp_up(mapargs)
  if current_temp < HIGHEST_TEMP then
      current_temp = current_temp + 1
      gre.set_value('thermostat_layer.temp_val.temp', string.format('%s˚', current_temp))
  end
end

--- Thermostat Screen: Increase temperature
-- @param gre#context mapargs
function cb_temp_down(mapargs) 
  if current_temp > LOWEST_TEMP then
      current_temp = current_temp -1
      gre.set_value('thermostat_layer.temp_val.temp', string.format('%s˚', current_temp))
  end  
end

--- Thermostat Screen: screenshow.post
-- @param gre#context mapargs
function cb_init_thermostat(mapargs)
  update_fan_state(gre.get_value('thermostat_layer.fan_control.fan_state'))
end

--- Screen hide on thermostat screen
function cb_thermostat_hide()
  clear_fan_animation()
end

--- Animates between heating / cooling mode on Thermostat screen
-- @param gre#context mapargs
function cb_change_cooling(mapargs)
  local state = gre.get_value('thermostat_layer.mode_control.mode_state')
  local animation_id = ''

  if state == MODE_COOLING then
      animation_id = 'cooling_to_heating_thermostat'
      state = MODE_HEATING
  elseif state == MODE_HEATING then
      animation_id = 'heating_to_off_thermostat'
      state = MODE_OFF
  else
      animation_id = 'off_to_cooling_thermostat'
      state = MODE_COOLING
  end
  
  gre.animation_trigger(animation_id)
  gre.set_value('thermostat_layer.mode_control.mode_state', state)
end

--- Cycles through fan modes on Thermostat screen
-- @param gre#context mapargs
function cb_change_fan(mapargs)
  local state = gre.get_value('thermostat_layer.fan_control.fan_state')
  if state == FAN_AUTO then 
    state = FAN_ON
  elseif state == FAN_ON then 
    state = FAN_OFF
  elseif state == FAN_OFF then 
    state = FAN_AUTO
  end
  
  update_fan_state(state)
end

--- Secrurity Screen: Enter Passcode
-- @param gre#context mapargs
function cb_change_pwd(mapargs)   
  if string.len(pwd) + 1 > PASSCODE_LENGTH then
      print(string.format('The length of passcode should be %d', PASSCODE_LENGTH))
      return
  end
  
  local char = mapargs.char
  pwd = string.format('%s%s', pwd, char)
  
  local len = string.len(pwd)
  local star = string.rep('•', len)
  local dash = string.rep('-', PASSCODE_LENGTH - len)
  local pwd_text = string.format('%s%s', star, dash)
  
  gre.set_value('security_keypad_layer.pwd_text', pwd_text)
end

--- Backspace is pressed on security screen
-- @param gre#context mapargs
function cb_delete_pwd(mapargs)
  pwd = string.sub(pwd, 1, -2)
  
  local len = string.len(pwd)
  local star = string.rep('•', len)
  local dash = string.rep('-', PASSCODE_LENGTH - len)
  local pwd_text = string.format('%s%s', star, dash)
  
  gre.set_value('security_keypad_layer.pwd_text', pwd_text)
end

--- Enter button is pressed on security screen
--- @param gre#context mapargs
function cb_enter_pwd(mapargs)
  local data = {}
  local status = ''
  local image = ''
  local animation_id = ''
  
  if pwd == PASSCODE then
      animation_id = 'lock_open_security'
      status = 'Disarmed'
      image = 'images/security_disarmed.mpeg'
  else
      animation_id = 'lock_close_security'
      status = 'Armed'
      image = 'images/security_armed.mpeg'
  end
  
  gre.animation_trigger(animation_id)
  
  data = {
      ['security_layer.status_label'] = status,
      ['security_layer.video_control.video'] = image    
  }
  
  gre.set_data(data)
end

--- Temperature unit is changed in settings
-- @param gre#context mapargs
function cb_change_unit(mapargs)
  if g_unit == UNIT_CELSIUS then
    g_unit = UNIT_FAHRENHEIT
  else 
    g_unit = UNIT_CELSIUS
  end
  
  convert_thermostat_temps()
  convert_weather_temps()
end

--- Press on slider control on settings screen
-- @param gre#context mapargs
function cb_slider_press(mapargs)
  active_slider = mapargs.context_control
  calculate_slider_position(mapargs.context_control, mapargs.context_event_data.x)
 end

--- Tracks motion on slider in settings screen
-- @param gre#context mapargs
function cb_slider_motion(mapargs)
  if (active_slider == nil) then
      return
  end

  if (active_slider == mapargs.context_control) then
      calculate_slider_position(mapargs.context_control, mapargs.context_event_data.x)
  end
end

--- Release slider control on settings screen
function cb_slider_release()
  active_slider = nil
end

--- Incoming SBIO event to update temperature on weather screen
-- @param gre#context mapargs
-- @field value Temperature in celsius
function cb_update_temp(mapargs)
  local value = mapargs.context_event_data.value
  
  -- incoming temp value is in celsius
  if g_unit ~= UNIT_CELSIUS then 
    value = celsius_to_fahrenheit(value)
  end
  
  gre.set_value('weather_layer.weather_day_control.temp_text', value)
end

--- Navigate to a new screen
-- @param gre#context mapargs
function cb_transition(mapargs)
  local current_screen = mapargs.context_screen
  local control = mapargs.context_control
  local target_screen = gre.get_value(string.format('%s.screen_name', control))
  
  if current_screen == target_screen then return end
  
  hide_info_layer(current_screen)
  
  if (current_screen == 'thermostat') then
    gre.set_value('target_sc', target_screen)
    gre.animation_trigger('buttons_hide_thermostat')
  else
    screen_transition(target_screen)
  end
end
