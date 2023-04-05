package funkin.ui;

import flixel.FlxSprite;
import haxe.Json;
import lime.utils.Assets;
// import flxtyped group
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.util.FlxSort;

class StickerSubState extends MusicBeatSubstate
{
  var grpStickers:FlxTypedGroup<StickerSprite>;

  public function new():Void
  {
    super();

    grpStickers = new FlxTypedGroup<StickerSprite>();
    add(grpStickers);

    var stickerInfo:StickerInfo = new StickerInfo('stickers-set-1');
    for (stickerSets in stickerInfo.getPack("all"))
    {
      for (stickerShit in stickerInfo.getStickers(stickerSets))
      {
        // for loop jus to repeat it easy easy easy
        for (i in 0...FlxG.random.int(1, 4))
        {
          var sticky:StickerSprite = new StickerSprite(0, 0, stickerInfo.name, stickerShit);
          sticky.x -= sticky.width / 2;
          sticky.y -= sticky.height / 2;
          sticky.visible = false;
          sticky.angle = FlxG.random.int(-60, 70);
          // sticky.flipX = FlxG.random.bool();
          grpStickers.add(sticky);

          sticky.timing = FlxG.random.float(0, 1.5);

          new FlxTimer().start(sticky.timing, function(_) {
            sticky.visible = true;

            new FlxTimer().start((1 / 24) * 2, _ -> {
              sticky.scale.x = sticky.scale.y = FlxG.random.float(0.97, 1.02);
              // sticky.angle *= FlxG.random.float(0, 0.05);
            });
          });
        }
      }
    }

    FlxG.random.shuffle(grpStickers.members);

    for (ind => sticker in grpStickers.members)
    {
      sticker.x += (ind % 7) * sticker.width;
      sticker.y += Math.floor(ind / 6) * sticker.height;
    }

    grpStickers.sort((ord, a, b) -> {
      return FlxSort.byValues(ord, a.timing, b.timing);
    });
  }
}

class StickerSprite extends FlxSprite
{
  public var timing:Float = 0;

  public function new(x:Float, y:Float, stickerSet:String, stickerName:String):Void
  {
    super(x, y, Paths.image('transitionSwag/' + stickerSet + '/' + stickerName));
    height = 100;
    width = 190;
    antialiasing = true;
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
