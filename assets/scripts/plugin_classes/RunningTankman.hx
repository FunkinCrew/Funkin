
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxG;
import Conductor;
class RunningTankman extends FlxSprite {
    public var tankSpeed = 0.7;
    public var goingRight = false;
    public var strumTime = 0;
    public var hscriptPath = "assets/images/custom_stages";
    public var endingOffset = FlxG.random.float(0.6, 1);
    public function new (?x=0, y=0, scriptPath:String) {
        super(x, y);
        this.hscriptPath = scriptPath;
        frames = FlxAtlasFrames.fromSparrow(hscriptPath + 'tankmanKilled1.png', hscriptPath + 'tankmanKilled1.xml');
        antialiasing = true;
        animation.addByPrefix("run", "tankman running", 24, true);
        animation.addByPrefix("shot", "John Shot " + FlxG.random.int(1,2), 24, false);
        animation.play("run");
        animation.curAnim.curFrame = FlxG.random.int(0, animation.curAnim.frames.length - 1);
        updateHitbox();
        setGraphicSize(Std.int(0.8 * width));
        updateHitbox();
        trace(":hueh:");

    }
    public function resetShit(x, y, goingRight) {
        this.x = x;
        this.y = y;
        this.goingRight = goingRight;
        endingOffset =  FlxG.random.float(50, 200);
        tankSpeed = FlxG.random.float(0.6, 1);
        if (goingRight) flipX = true;
    }
    override function update(elapsed) {
        super.update(elapsed);
        if (x >= 1.2 * FlxG.width || x <= -0.5 * FlxG.width) {
            visible = false;
        } else {
            visible = true;
        }
        if (animation.curAnim.name == "run") {
            var fuck = 0.74 * FlxG.width + endingOffset;
            if (goingRight) {
                fuck = 0.02 * FlxG.width - endingOffset;
                x = fuck + (Conductor.songPosition - strumTime) * tankSpeed;
            } else {
                x = fuck - (Conductor.songPosition - strumTime) * tankSpeed;
            }
        }
        if (Conductor.songPosition > strumTime) {
            animation.play("shot");
            if (goingRight) {
                offset.y = 200;
                offset.x = 300;
            }
        }
        if (animation.curAnim.name == "shot" && animation.curAnim.finished) {
            kill();
        }
    }
}