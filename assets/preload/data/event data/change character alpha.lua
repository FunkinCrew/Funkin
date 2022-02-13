function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "change character alpha" then
        local alpha = tonumber(argument2)

        if alpha == nil then
            alpha = 0.5
        end

        setActorAlpha(alpha, getCharFromEvent(argument1))
    end
end