local function dump(o)
	if type(o) == 'table' then
	   local s = '{ '
	   for k,v in pairs(o) do
		  if type(k) ~= 'number' then k = '"'..k..'"' end
		  s = s .. '['..k..'] = ' .. dump(v) .. ','
	   end
	   return s .. '} '
	else
	   return tostring(o)
	end
end

local table_utils = {}

function table_utils:clear_table(tbl)
    for k in pairs(tbl) do
        tbl[k] = nil
    end
end

function table_utils:dump_table(tbl)
    print(dump(tbl))
end

function table_utils:split_string(input, sep)
	local split = {}
	for str in string.gmatch(input, "([^"..sep.."]+)") do
		table.insert(split, str)
	end
	return split
end

return table_utils