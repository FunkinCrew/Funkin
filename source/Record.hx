import flixel.util.FlxGradient;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;
import flixel.FlxSprite;

// :wink: "inspired" by exr

class Record extends FlxTypedSpriteGroup<FlxSprite> {
    // i'm gonna pull some valve style code :hueh:
    var recordsprite:FlxSprite;
    var gradSprite:FlxSprite;
    var semicircles:Array<FlxSprite> = [];
    var icon:HealthIcon;
    var reordering:Bool = false;
    public function new(X:Float=0, Y:Float=0, colors:Array<String>, ?character:String="bf", ?pixel:Bool=false) {
        super();
        reordering = true;
        var suffix = pixel ? "-pixel" : "";
        recordsprite = new FlxSprite().loadGraphic('assets/images/record$suffix.png');
        recordsprite.centerOffsets();
        recordsprite.antialiasing = true;
        for (i in 0...2) {
            var semicircle = new FlxSprite().loadGraphic('assets/images/record-center$suffix.png');
            semicircles.push(semicircle);
			semicircle.angle = i * 180;
			semicircle.origin.set(recordsprite.origin.x, recordsprite.origin.y);
            semicircle.centerOffsets();
            add(semicircle);
            
        }
        gradSprite = new FlxSprite();
        var sussyColors = [];
        for (color in colors) {
            var cooolor = FlxColor.fromString(color);
            sussyColors.push(cooolor);
        }
        var gradient = FlxGradient.createGradientBitmapData(Std.int(recordsprite.width), Std.int(recordsprite.height), sussyColors);
        gradSprite.loadGraphic(gradient);
        gradSprite.blend = "multiply";
        
        gradSprite.x += recordsprite.width/2 - gradSprite.width/4;
        gradSprite.y += recordsprite.height/2 - gradSprite.height/4;
		gradSprite.centerOffsets(true);
        icon = new HealthIcon(character);
		icon.origin.set(origin.x, origin.y);
        icon.x = recordsprite.width/2 - (icon.width/2);
        icon.y = recordsprite.height/2 - (icon.height/2);
        gradSprite.centerOffsets(true);
        add(gradSprite);
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
		var sussyColors = [];
		for (color in colors)
		{
			var cooolor = FlxColor.fromString(color);
			sussyColors.push(cooolor);
		}
		var gradient = FlxGradient.createGradientBitmapData(Std.int(recordsprite.width/2), Std.int(recordsprite.height/2), sussyColors, 10);
        gradSprite.loadGraphic(gradient);
		gradSprite.centerOffsets();
        if (useColors.length == 1) {
            useColors[1] = useColors[0];
        }
        icon.switchAnim(character);
        /*
        var i = 0;
		for (color in 0...2)
		{
			semicircles[color].color = useColors[color];
		} */
        reordering = false;
    }
}