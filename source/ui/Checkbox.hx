package ui;

import flixel.util.FlxTimer;
import flixel.FlxSprite;

class Checkbox extends FlxSprite
{
    public var sprTracker:FlxSprite;
    public var checked:Bool = false;

    public function new(tracking:FlxSprite)
    {
        super();

        frames = Paths.getSparrowAtlas("options menu/checkbox");

        animation.addByPrefix("static", "Unchecked", 24, true);
        animation.addByPrefix("checked", "Checked", 24, false);

        animation.play("static");

        updateHitbox();

        this.sprTracker = tracking;
        scrollFactor.set();

        antialiasing = true;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(sprTracker != null)
            setPosition(sprTracker.x + sprTracker.width + 5, sprTracker.y);

        if(animation.curAnim.name == "static" && checked)
        {
            animation.play("checked", true);
            updateHitbox();
        }
        else if(animation.curAnim.name == "checked" && !checked)
        {
            animation.play("static", true);
            updateHitbox();
        }
    }
}