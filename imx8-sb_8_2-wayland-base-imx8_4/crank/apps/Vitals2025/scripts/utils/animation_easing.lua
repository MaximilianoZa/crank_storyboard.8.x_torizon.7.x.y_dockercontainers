--[[
Easing equations can be found here:
https://github.com/EmmanuelOga/easing

Disclaimer for Robert Penner's Easing Equations license:
Copyright © 2001 Robert Penner

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

local pow  = math.pow
local sin  = math.sin
local cos  = math.cos
local pi   = math.pi
local sqrt = math.sqrt
local abs  = math.abs
local asin = math.asin

local function out_quint(t, b, c, d)
	t = t / d - 1
	return c * (pow(t, 5) + 1) + b
end

local function in_quint(t, b, c, d)
	t = t / d
	return c * pow(t, 5) + b
end

local function out_in_quint(t, b, c, d)
	if t < d / 2 then
		return out_quint(t * 2, b, c / 2, d)
	else
		return in_quint((t * 2) - d, b + c / 2, c / 2, d)
	end
end

return {
	out_quint = out_quint,
	in_quint = in_quint,
	out_in_quint = out_in_quint
}