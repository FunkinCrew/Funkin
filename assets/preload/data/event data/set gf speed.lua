function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "set gf speed" then
        if tonumber(argument1) ~= nil then
            setProperty("", "gfSpeed", math.floor(tonumber(argument1) + 0.1))
        end
    end
end