function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "no shader" then
        local actor = getCharFromEvent(argument1)
        
        setActorNoShader(actor)
    end
end