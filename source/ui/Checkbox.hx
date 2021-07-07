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

        animation.addByPrefix("unchecked", "Check Box unselected", 24);
        animation.addByPrefix("changed", "Check Box selecting animation", 24, false);
        animation.addByPrefix("checked", "Check Box Selected Static", 24);

        animation.play("unchecked");

        this.sprTracker = tracking;
        scrollFactor.set();

        animation.finishCallback = function(name:String) {
            if(name == "changed")
            {
                if(checked)
                    animation.play("checked");
                else
                    animation.play("unchecked");
            }
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (sprTracker != null)
            setPosition(sprTracker.x - width - 5, sprTracker.y);

        if (animation.curAnim.name == "unchecked" && checked)
        {
            animation.play("changed");
        }

        if (animation.curAnim.name == "checked" && !checked)
        {
            animation.play("changed", false, true);
        }
    }
}