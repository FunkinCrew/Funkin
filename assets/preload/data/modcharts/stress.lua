function start(song)
    setCharacterShouldDance("girlfriend", false)
end

function beatHit(curBeat)
    if getPlayingActorAnimation("girlfriend") == "shoot2" then
        playActorAnimation("girlfriend", "shoot2", true, false, 23)
    end
end