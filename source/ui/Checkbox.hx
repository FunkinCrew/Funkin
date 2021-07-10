package ui;

import flixel.FlxSprite;

class Checkbox extends FlxSprite
{
    public var sprTracker:FlxSprite;
    public var checked:Bool = false;

    public function new(tracking:FlxSprite)
    {
        super();

        frames = Paths.getSparrowAtlas("optionsmenu/checkbox");

        animation.addByPrefix("static", "Check Box unselected", 24, false);
        animation.addByPrefix("checked", "Check Box selecting animation", 24, false);

        animation.play("static");

        setGraphicSize(Std.int(width * 0.5));
        updateHitbox();

        this.sprTracker = tracking;
        scrollFactor.set();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        switch (animation.curAnim.name)
        {
            case "checked":
                offset.set(17, 70);
            case "static":
                offset.set();
        }

        if (sprTracker != null)
            setPosition(sprTracker.x + sprTracker.width  + 5, sprTracker.y);

        if (animation.curAnim.name == "static" && checked)
            animation.play("checked", true);
        else if(animation.curAnim.name == "checked" && !checked)
            animation.play("static");
    }
}