local csv = require('utils.csv_reader')

local file_utils = {}

--- Load the contents of a given CSV file
--- @function file_utils:load_file
--- @param file string the CSV file to load
--- @param index? number (optional) the csv index to pull data from
--- @return table values the CSV contents in table form
function file_utils:load_file(file, index)
    local index = index or 1
    local path = string.format("%s/../data/%s", gre.SCRIPT_ROOT, file)
    local db = csv.open(path)
    if (db == nil) then
        return {}
    end
    
    local values = {}
    for line in db:lines() do
        table.insert(values, line[index])
    end
    db:close()

    return values
end

return file_utils