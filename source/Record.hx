import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;
import flixel.FlxSprite;

// :wink: "inspired" by exr

class Record extends FlxTypedSpriteGroup<FlxSprite> {
    // i'm gonna pull some valve style code :hueh:
    var recordsprite:FlxSprite;
    var semicircles:Array<FlxSprite> = [];
    var icon:HealthIcon;
    var reordering:Bool = false;
    public function new(X:Float=0, Y:Float=0, colors:Array<String>, ?character:String="bf") {
        super();
        reordering = true;
        recordsprite = new FlxSprite().loadGraphic('assets/images/record.png');
        recordsprite.antialiasing = true;
        for (i in 0...2) {
            var semicircle = new FlxSprite().loadGraphic('assets/images/record-center.png');
            semicircles.push(semicircle);
            add(semicircle);
            semicircle.angle = i * 180;
        }
        icon = new HealthIcon(character);
        icon.x = recordsprite.width/2 - (icon.width/2);
        icon.y = recordsprite.height/2 - (icon.height/2);

        changeColor(colors);
        add(recordsprite);
        add(icon);
        x = X;
        y = Y;
        reordering = false;
    }
    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (reordering)
            return;
        angle += 30 * elapsed;
    }
    public function changeColor(colors:Array<String>, ?character:String="bf") {
        var useColors = [];
        reordering = true;
        for (toColor in colors) {
            useColors.push(FlxColor.fromString(toColor));
        }
        if (useColors.length == 1) {
            useColors[1] = useColors[0];
        }
        icon.switchAnim(character);
        var i = 0;
		for (color in 0...2)
		{
			semicircles[color].color = useColors[color];
		} 
        reordering = false;
    }
}