package;

import flixel.FlxState;

class RickRollState extends FlxState {
    public override function create() {
        super.create();

        var video = new MP4Handler();
        video.playMP4(Paths.video("rickroll"), new MainMenuState(), null, false, false, false);
    }
}