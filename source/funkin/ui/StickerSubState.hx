package funkin.ui;

import flixel.FlxSprite;
import haxe.Json;
import lime.utils.Assets;

class StickerSubState extends MusicBeatSubstate
{
  public function new():Void
  {
    super();

    var stickerInfo:StickerInfo = new StickerInfo('stickers-set-1');
    for (stickerSets in stickerInfo.getPack("all"))
    {
      for (stickerShit in stickerInfo.getStickers(stickerSets))
      {
        var sticky:StickerSprite = new StickerSprite(FlxG.random.int(0, FlxG.width), FlxG.random.int(0, FlxG.height), stickerInfo.name, stickerShit);
        add(sticky);
      }
    }
  }
}

class StickerSprite extends FlxSprite
{
  public function new(x:Float, y:Float, stickerSet:String, stickerName:String):Void
  {
    super(x, y, Paths.image('transitionSwag/' + stickerSet + '/' + stickerName));
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
    var path = Paths.file('images/transitionSwag/' + stickerSet + '/stickers.json');
    var json = Json.parse(Assets.getText(path));
    trace(json);

    // doin this dipshit nonsense cuz i dunno how to deal with casting a json object with
    // a dash in its name (sticker-packs)
    var jsonInfo:StickerShit = cast json;

    this.name = jsonInfo.name;
    this.artist = jsonInfo.artist;

    stickerPacks = new Map<String, Array<String>>();

    for (field in Reflect.fields(json.stickerPacks))
    {
      var stickerFunny = json.stickerPacks;
      var stickerStuff = Reflect.field(stickerFunny, field);

      stickerPacks.set(field, cast stickerStuff);

      trace(field);
      trace(Reflect.field(stickerFunny, field));
    }

    trace(stickerPacks);

    // creates a similar for loop as before but for the stickers
    stickers = new Map<String, Array<String>>();

    for (field in Reflect.fields(json.stickers))
    {
      var stickerFunny = json.stickers;
      var stickerStuff = Reflect.field(stickerFunny, field);

      stickers.set(field, cast stickerStuff);

      trace(field);
      trace(Reflect.field(stickerFunny, field));
    }

    trace(stickers);

    // this.stickerPacks = cast jsonInfo.stickerPacks;
    // this.stickers = cast jsonInfo.stickers;

    // trace(stickerPacks);
    // trace(stickers);

    // for (packs in stickers)
    // {
    //   // this.stickers.set(packs, Reflect.field(json, "sticker-packs"));
    //   trace(packs);
    // }
  }

  public function getStickers(stickerName:String):Array<String>
  {
    return this.stickers[stickerName];
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
