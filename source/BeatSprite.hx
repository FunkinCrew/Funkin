package;
import flixel.FlxSprite;
/**
 * A sprite that can dance based on the beat. Used mostly for custom stages.
 */
class BeatSprite extends FlxSprite {
    var danceDir : Bool = false;
    public var shouldDance : Bool = false;
    public function new (x : Float, y : Float, shouldDanceVar : Bool = false) {
        super(x, y);
        shouldDance = shouldDanceVar;
    }
    public function dance():Void {
        // if character doesn't have dance anim, don't dance
        if (!shouldDance) return;
        danceDir = !danceDir;

        if (danceDir) {
            animation.play("danceRight", true);
        } else {
            animation.play("danceLeft", true);
        }
    }

}