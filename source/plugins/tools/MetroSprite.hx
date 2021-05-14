package plugins.tools;

import flixel.FlxSprite;
// utility sprite that handles dancing for you
class MetroSprite extends DynamicSprite {
    var danceDir:Bool = false;
    public var danceInPlace:Bool = false;

    public function new (x:Float, y:Float, danceInPlace:Bool) {
        super(x, y);
        this.danceInPlace = danceInPlace;
    }
    public function dance(beat:Int):Void {
        danceDir = !danceDir;
        if (danceInPlace) {
            animation.play("idle", true);
        } else if (danceDir) {
            animation.play("danceRight", true);
        } else {
            animation.play("danceLeft", true);
        }
    }
 }