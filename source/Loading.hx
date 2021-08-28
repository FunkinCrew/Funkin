package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxState;

#if windows
import Discord.DiscordClient;
#end
#if sys
import sys.FileSystem;
#end

using StringTools;

class Loading extends FlxState
{
    var sprite:FlxSprite;
    var text:FlxText=new FlxText();
    var music:Array<String> = [];

    var songDone:Bool = false;

    override public function create() {
        sprite = new FlxSprite(FlxG.width / 2, 15000).loadGraphic(Paths.image('WBLogo'));
		sprite.x -= sprite.width / 2;
		sprite.y -= sprite.height / 2 + 100;
		text.y -= sprite.height / 2 - 125;
		text.x -= 170;
		sprite.setGraphicSize(Std.int(sprite.width * 0.6));
		sprite.antialiasing = false;
        add(sprite);
        add(text);

        super.create();
    }

    override public function update(elapsed:Float) {
        if(!songDone)
            cacheSongs();
        else if (songDone) {
            FlxG.switchState(new TitleState()); }
        super.update(elapsed);
    }

    function cacheSongs() {
        for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/songs")))
            {
                music.push(i);
                text.text = 'Caching ' + i + '...';
            }
        songDone = true;
    }
}