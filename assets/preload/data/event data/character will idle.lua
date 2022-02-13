function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "character will idle" then
        setCharacterShouldDance(getCharFromEvent(argument1), string.lower(tostring(argument2)) == "true")
    end
end