function split(inputstr, sep)
    if sep == nil then
       sep = "%s"
    end

    local t = { }

    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end

    return t
 end

function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "add trail" then
        local actor = argument1

        local length = 10
        local delay = 3
        local alpha = 0.4
        local diff = 0.05

        for i,v in ipairs(split(argument2, ",")) do
            if i == 1 then
                length = tonumber(v)
            end

            if i == 2 then
                delay = tonumber(v)
            end

            if i == 3 then
                alpha = tonumber(v)
            end

            if i == 4 then
                diff = tonumber(v)
            end
        end
        
        addActorTrail(actor, length, delay, alpha, diff)
    end
end