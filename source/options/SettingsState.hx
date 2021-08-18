package options;

import flixel.addons.display.FlxTiledSprite;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.*;

class SettingsState extends MusicBeatState {
    var tile:FlxTiledSprite;
    override public function create() {
        add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(149,221,125)));

        tile = new FlxTiledSprite(Paths.image('credIcon'), FlxG.width, FlxG.height);
        tile.scrollX = 10;
        tile.scrollY = 10;
        add(tile);
        
        var checkbox = new FlxUICheckBox(0, 0, null, null, "qwe");
        checkbox.setGraphicSize(Std.int(checkbox.width * 4));
        checkbox.updateHitbox();
        add(checkbox);

        FlxG.bitmap.clearCache();
        
        super.create();
    }

    override public function update(dt) {
        super.update(dt);

        var scrollShit:Float = FlxG.height * 0.3 * 0.25 * FlxG.elapsed;
        tile.alpha = 0.1;
        tile.scrollX -= scrollShit;
        tile.scrollY += scrollShit;
    }
}