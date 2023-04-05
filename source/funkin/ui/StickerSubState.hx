package funkin.ui;

import flixel.FlxSprite;
import haxe.Json;

class StickerSubState extends MusicBeatSubstate
{
  public function new():Void
  {
    super();

    var stickerInfo:StickerInfo = new StickerInfo('sticker-set-1');
    for (stickerSets in stickerInfo.getPack("all"))
    {
      trace(stickerSets);
    }
  }
}

class StickerSprite extends FlxSprite
{
  public function new(x:Float, y:Float, stickerSet:String, stickerName:String):Void
  {
    super(x, y, Paths.file('assets/images/transitionSwag/' + stickerSet + '/' + stickerName + '.png'));
  }
}

class StickerInfo
{
  public var name:String;
  public var artist:String;
  public var stickers:Map<String, Array<String>>;
  public var stickerPacks:Map<String, Array<String>>;

  public function new(stickerSet:String):Void
  {
    var jsonInfo:StickerShit = cast Json.parse(Paths.file('assets/images/transitionSwag/' + stickerSet + '/stickers.json'));

    this.name = jsonInfo.name;
    this.artist = jsonInfo.artist;
    this.stickers = jsonInfo.stickers;
    this.stickerPacks = jsonInfo.stickerPacks;
  }

  public function getPack(packName:String):Array<String>
  {
    return this.stickerPacks[packName];
  }
}

// somethin damn cute just for the json to cast to!
typedef StickerShit =
{
  name:String,
  artist:String,
  stickers:Map<String, Array<String>>,
  stickerPacks:Map<String, Array<String>>
}
