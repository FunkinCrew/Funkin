package funkin.ui;

import haxe.Json;

class StickerSubState extends MusicBeatSubstate
{
  public function new():Void
  {
    super();

    var stickerInfo:StickerInfo = new StickerInfo('sticker-set-1');
  }
}

class StickerInfo
{
  public var name:String;
  public var artist:String;
  public var stickers:Stickers;
  public var stickerPacks:StickerPacks;

  public function new(stickerSet:String):Void
  {
    var jsonInfo:Dynamic = Json.parse(Paths.file('assets/images/transitionSwag/' + stickerSet + '/stickers.json'));
  }
}

class Stickers
{
  var name:String;
  var stickers:Array<String>;
}

class StickerPacks
{
  var name:String;
  // which stickers are in a pack, refers to the class Stickers!
  var stickerPacks:Array<Stickers>;
}
