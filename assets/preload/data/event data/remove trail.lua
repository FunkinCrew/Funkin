function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "remove trail" then
        removeActorTrail(argument1)
    end
end