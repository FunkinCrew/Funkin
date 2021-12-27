function beatHit(beat)
    if cameraZooms then
        if beat >= 168 and beat < 200 and getCamZoom() < 1.35 then
            setCamZoom(getCamZoom() + 0.015)
            setHudZoom(getHudZoom() + 0.03)
        end
    end
end