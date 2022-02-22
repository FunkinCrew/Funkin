function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "3d shader" then
        local actor = getCharFromEvent(argument1)

        local funnySplit = splitString(argument2, ",")

        setActor3DShader(actor, tonumber(funnySplit[1]), tonumber(funnySplit[2]), tonumber(funnySplit[3]))
    end
end

function splitString(stringParam, delemiter) -- thx to me for making this for the hypno's lullaby port
    local strings = {}

    local funnyString = ""

    for i = 1, #stringParam do
        if string.sub(stringParam, i, i) == delemiter then
            table.insert(strings, funnyString)
            funnyString = ""
        end

        if string.sub(stringParam, i, i) ~= delemiter or delemiter == "" then
            funnyString = funnyString .. string.sub(stringParam, i, i)
        end
    end

    table.insert(strings, funnyString)
    
    return strings
end