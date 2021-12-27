package ui;

import flixel.FlxSprite;

/**
* An FlxSprite that tracks another sprite's position and scale to appear next to it.
*/
class TrackerSprite extends FlxSprite
{
    /**
	 * Sprite being tracked.
	 */
    public var sprTracker:FlxSprite;

	/**
	 * Variable that is used to change the amount of x added to the end of the tracker sprite for an offset.
	 */
    public var xOffset:Float = 10;

    /**
	 * Variable that is used to change the amount of y added to the top of the tracker sprite for an offset.
	 */
    public var yOffset:Float = -30;

    /**
	 * Direction the sprite is currently tracking to.
	 */
    public var direction:TrackerDirection = RIGHT;

	/**
	 * Creates a `TrackerSprite` with a specific tracker, x offset, y offset, and tracking direction.
	 *
	 * @param   Tracker   The `FlxSprite` to track.
	 *
	 * @param   xOffset   The X Offset added to the Tracker Sprite's Position.
	 * @param   yOffset   The Y Offset added to the Tracker Sprite's Position.
	 *
	 * @param   Direction The `TrackerDirection` that the Tracker Sprite uses to determine what direction to track to.
	 *
	*/
    public function new(?tracker:FlxSprite, ?xOff:Float, ?yOff:Float, ?dir:TrackerDirection)
    {
        if(tracker != null)
            sprTracker = tracker;

        if(xOff != null)
            xOffset = xOff;

        if(yOff != null)
            yOffset = yOff;

        if(dir != null)
            direction = dir;

        super(x,y);
    }

    /**
	 * Updates sprite's position around the tracked one.
	 */
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(sprTracker != null)
        {
            switch(direction)
            {
                case RIGHT:
                    setPosition(sprTracker.x + sprTracker.width + xOffset, sprTracker.y + yOffset);
                case LEFT:
                    setPosition(sprTracker.x - width - xOffset, sprTracker.y + yOffset);
                case UP:
                    setPosition((sprTracker.x + (sprTracker.width / 2) - (width / 2)), sprTracker.y - sprTracker.height + yOffset);
                case DOWN:
                    setPosition((sprTracker.x + (sprTracker.width / 2) - (width / 2)), sprTracker.y + sprTracker.height - yOffset);
                case NONE:
                    setPosition(x,y); // do nothing lol
            }
        }
    }
}

/**
    A Simple Enum to track Direction of a `TrackingSprite`
**/
enum TrackerDirection {
    RIGHT;
    LEFT;
    UP;
    DOWN;
    NONE;
}