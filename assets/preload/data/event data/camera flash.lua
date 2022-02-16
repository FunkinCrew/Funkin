function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "camera flash" then
        local colorString = string.lower(argument1)
        local duration = tonumber(argument2)

        if duration == nil then
            duration = 1
        end

        flashCamera("game", colorString, duration)
    end
end