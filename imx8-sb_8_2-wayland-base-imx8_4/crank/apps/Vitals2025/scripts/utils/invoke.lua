
local invoke = {}

---
-- function for invoking a method from a specific module
-- @param #string module - The name of the module that contains the method being invoked
-- @param #string method - The name of the method being invoked
-- @param gre#context mapargs
-- 
function invoke.module( module, method, mapargs )
    local status, retval = pcall(
        function(m)
            return require(m)
        end,
        module
    )
    if (status == false) then
        print(string.format("Couldn't get module %s: %s", module, retval))
        return
    end

    local instance = retval
    if (instance == nil or type(instance) ~= 'table') then
        print(string.format("Couldn't get module %s", instance))
        return
    end

    if (instance[method] == nil) then
        print(string.format('Method %s not found in %s', method, module))
        return
    end

    status, retval = pcall(
        function()
            return instance[method](instance, mapargs)
        end
    )
    if (status == false) then
        print(string.format("Couldn't invoke method %s: %s", method, retval))
        return
    end
    
    return retval
end


return invoke
