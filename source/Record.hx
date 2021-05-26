import flixel.graphics.frames.FlxAtlasFrames;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import flixel.util.FlxGradient;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import openfl.display.BlendMode;
import Highscore.FCLevel;
// :wink: "inspired" by exr

class Record extends FlxTypedSpriteGroup<FlxSprite> {
    // i'm gonna pull some valve style code :hueh:
    var recordsprite:FlxSprite;
    var gradSprite:FlxSprite;
    var centerPart:FlxSprite;
    var icon:HealthIcon;
    var reordering:Bool = false;
    var curWeek = -1;
    var sussyBackup:BitmapData;
    var completed:Bool = false;
    var shiney:FlxSprite;
    public function new(X:Float=0, Y:Float=0, colors:Array<String>, ?character:String="bf", ?week:Int = -1, ?completion:Bool) {
        super();
        reordering = true;
        var sussyRecordGraphic:BitmapData;
        if (week == -1) {
            if (completion)
				sussyRecordGraphic = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-gold.png');
            else
                sussyRecordGraphic = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-record.png');
            sussyBackup = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-center.png');
        } else {
            if (completion) {
				if (FNFAssets.exists('assets/images/campaign-ui-week/week$week-gold.png'))
				{
					sussyRecordGraphic = FNFAssets.getBitmapData('assets/images/campaign-ui-week/week$week-gold.png');
				}
				else
				{
					sussyRecordGraphic = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-gold.png');
				}
            } else {
				if (FNFAssets.exists('assets/images/campaign-ui-week/week$week-record.png'))
				{
					sussyRecordGraphic = FNFAssets.getBitmapData('assets/images/campaign-ui-week/week$week-record.png');
				}
				else
				{
					sussyRecordGraphic = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-record.png');
				}
            }
            
            if (FNFAssets.exists('assets/images/campaign-ui-weeks/week$week-center.png')) {
				sussyBackup = FNFAssets.getBitmapData('assets/images/campaign-ui-weeks/week$week-center.png');
            } else {
				sussyBackup = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-center.png');
            }
        }
        completed = completion;
        curWeek = week;
        recordsprite = new FlxSprite().loadGraphic(sussyRecordGraphic);
        recordsprite.centerOffsets();
        recordsprite.antialiasing = true;
        centerPart = new FlxSprite().loadGraphic(sussyBackup.clone());
		centerPart.origin.set(recordsprite.origin.x, recordsprite.origin.y);
		centerPart.centerOffsets();
        
        shiney = new FlxSprite(recordsprite.x, recordsprite.y);
		shiney.origin.set(recordsprite.origin.x, recordsprite.origin.y);
        icon = new HealthIcon(character);
		icon.origin.set(origin.x, origin.y);
        icon.x = recordsprite.width/2 - (icon.width/2);
        icon.y = recordsprite.height/2 - (icon.height/2);
		add(recordsprite);
		add(centerPart);
		add(icon);
        add(shiney);
        changeColor(colors);
        
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
    public function changeColor(colors:Array<String>, ?character:String="bf", ?week:Int = -1, ?rating:FCLevel = None) {
        reordering = true;
		var sussyColors = [];
		for (color in colors)
		{
			var cooolor = FlxColor.fromString(color);
			sussyColors.push(cooolor);
		}
		var sussyRecordGraphic:BitmapData;
        var sussyShine:BitmapData;
        var shineXml:String;
        if (week == -1)
        {
            if (rating >= Shit)
                sussyRecordGraphic = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-gold.png');
            else
                sussyRecordGraphic = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-record.png');
            sussyBackup = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-center.png');
            sussyShine = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-shine.png');
            shineXml = FNFAssets.getText('assets/images/campaign-ui-week/default-shine.xml');
        }
        else
        {
            if (rating >= Shit)
            {
                if (FNFAssets.exists('assets/images/campaign-ui-week/week$week-gold.png'))
                {
                    sussyRecordGraphic = FNFAssets.getBitmapData('assets/images/campaign-ui-week/week$week-gold.png');
                }
                else
                {
                    sussyRecordGraphic = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-gold.png');
                }
            }
            else
            {
                if (FNFAssets.exists('assets/images/campaign-ui-week/week$week-record.png'))
                {
                    sussyRecordGraphic = FNFAssets.getBitmapData('assets/images/campaign-ui-week/week$week-record.png');
                }
                else
                {
                    sussyRecordGraphic = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-record.png');
                }
            }
            if (FNFAssets.exists('assets/images/campaign-ui-week/week$week-shine.png')) {
				sussyShine = FNFAssets.getBitmapData('assets/images/campaign-ui-week/week$week-shine.png');
				shineXml = FNFAssets.getText('assets/images/campaign-ui-week/week$week-shine.png');
            } else {
				sussyShine = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-shine.png');
				shineXml = FNFAssets.getText('assets/images/campaign-ui-week/default-shine.xml');
            }
            if (FNFAssets.exists('assets/images/campaign-ui-week/week$week-center.png'))
            {
                sussyBackup = FNFAssets.getBitmapData('assets/images/campaign-ui-week/week$week-center.png');
            }
            else
            {
                sussyBackup = FNFAssets.getBitmapData('assets/images/campaign-ui-week/default-center.png');
            }
        }
        
        remove(shiney);
        recordsprite.loadGraphic(sussyRecordGraphic);
        shiney.frames = FlxAtlasFrames.fromSparrow(sussyShine, shineXml);
        shiney.animation.addByPrefix("shine", "shine", 15);
        shiney.animation.play("shine");
		shiney.origin.set(recordsprite.origin.x, recordsprite.origin.y);
        shiney.centerOffsets();
        shiney.antialiasing = true;
        
        add(shiney);
        if (rating < Good) {
            shiney.visible = false;
        } else {
            shiney.visible = true;
        }
		curWeek = week;
        var sussyGradThing = sussyBackup.clone();
		var sussyGradientMap = FlxGradient.createGradientBitmapData(Std.int(centerPart.width), Std.int(centerPart.height), sussyColors);
        sussyGradientMap.colorTransform(new Rectangle(0, 0, sussyGradientMap.width, sussyGradientMap.height), new ColorTransform(1, 1, 1, 0.8));
		sussyGradThing.copyPixels(sussyGradientMap, new Rectangle(0, 0, sussyGradientMap.width, sussyGradientMap.height), new Point(0, 0), sussyBackup,
			new Point(0, 0), true);
        centerPart.loadGraphic(sussyGradThing);
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