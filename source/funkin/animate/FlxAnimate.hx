package funkin.animate;

import funkin.animate.ParseAnimate.AnimJson;
import funkin.animate.ParseAnimate.Sprite;
import funkin.animate.ParseAnimate.Spritemap;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.group.FlxGroup;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import haxe.format.JsonParser;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

class FlxAnimate extends FlxSymbol
{
  // var myAnim:Animation;
  // var animBitmap:BitmapData;
  var jsonAnim:AnimJson;

  var sprGrp:FlxTypedGroup<FlxSymbol>;

  public function new(x:Float, y:Float)
  {
    super(x, y);

    sprGrp = new FlxTypedGroup<FlxSymbol>();

    var tests:Array<String> = ['tightBarsLol', 'tightestBars'];

    var folder:String = tests[1];

    frames = FlxAnimate.fromAnimate(Paths.file('images/' + folder + "/spritemap1.png"), Paths.file('images/$folder/spritemap1.json'));

    jsonAnim = cast CoolUtil.coolJSON(Assets.getText(Paths.file('images/$folder/Animation.json')));
    ParseAnimate.generateSymbolmap(jsonAnim.SD.S);
    ParseAnimate.resetFrameList();

    ParseAnimate.parseTimeline(jsonAnim.AN.TL, 0, 0);

    generateSpriteShit();

    /* var folder:String = 'tightestBars';
      coolParse = cast Json.parse(Assets.getText(Paths.file('images/' + folder + '/Animation.json')));

      // reverses the layers, for proper rendering!
      coolParse.AN.TL.L.reverse();
      super(x, y, coolParse);

      frames = FlxAnimate.fromAnimate(Paths.file('images/' + folder + '/spritemap1.png'), Paths.file('images/' + folder + '/spritemap1.json'));
     */

    // frames
  }

  override function draw()
  {
    // having this commented out fixes some wacky scaling bullshit?
    // or fixes drawing it twice?
    // super.draw();

    // renderFrame(coolParse.AN.TL, coolParse, true);

    actualFrameRender();
  }

  /**
   * Puts all the needed sprites into a FlxTypedGroup, and properly recycles them?
  **/
  function generateSpriteShit()
  {
    sprGrp.kill(); // kills group, maybe dont need to do this one so broadly? ehh whatev

    for (frameSorted in ParseAnimate.frameList)
    {
      for (i in frameSorted)
      {
        // instead of making them every frame, regenerate when needed?
        var spr:FlxSymbol = sprGrp.recycle(FlxSymbol); // redo this to recycle from a list later
        spr.frames = frames;
        spr.frame = spr.frames.getByName(i.frameName); // this one is fine
        spr.updateHitbox();

        // move this? wont work here!
        if (FlxG.keys.justPressed.I)
        {
          trace(i.frameName);
          trace(i.depthString);
          // trace("random lol: " + i.randomLol);
        }

        // cuz its in group, gets a lil fuckie when animated, need to go thru and properly reset each thing for shit like matrix!
        // merely resets the matrix to normal ass one!
        spr.transformMatrix.identity();
        spr.setPosition();

        /* for (swagMatrix in i.matrixArray)
          {
            var alsoSwag:FlxMatrix = new FlxMatrix(swagMatrix[0], swagMatrix[1], swagMatrix[4], swagMatrix[5], swagMatrix[12], swagMatrix[13]);
            spr.matrixExposed = true;
            spr.transformMatrix.concat(alsoSwag);
        }*/

        // i.fullMatrix.concat

        spr.matrixExposed = true;

        // trace(i.fullMatrix);

        if (i.fullMatrix.a < 0)
        {
          trace('negative?');
          trace(i.fullMatrix);
        }

        spr.transformMatrix.concat(i.fullMatrix);

        if (i.fullMatrix.a < 0)
        {
          trace('negative?');
          trace(i.fullMatrix);
          trace(spr.transformMatrix);
        }

        // trace(spr.transformMatrix);

        spr.origin.set();

        /* for (trpShit in i.trpArray)
          {
            spr.origin.x -= trpShit[0];
            spr.origin.y -= trpShit[1];
          }
         */
        // spr.alpha = 0.3;

        spr.antialiasing = true;
        sprGrp.add(spr);
        spr.alpha = 0.5;

        /*   if (i == "0225")
          {
            trace('FUNNY MATRIX!');
            trace(spr._matrix);
            trace("\n\n MATRIX MAP");
            for (m in ParseAnimate.matrixMap.get("0225"))
            {
              trace(m);
            }

            trace('\n\n');
        }*/
      }
    }

    // trace(sprGrp.length);
  }

  // fix render order of ALL layers!
  // seperate frameList into layers
  // go thru animate file to see how it should all be ordered
  // per frame symbol stuff to fix lip sync (in ParseAnimate?)
  // definitely need to dig through Animate.json stuff
  // something with TRP stuff, look through tighterBars (GF scene)
  // redo map stuff incase there's multiple assets
  // ONE CENTRAL THING FOR THIS DUMBASS BULLSHIT
  // sorted framelist put it all in there, then make i actually mean something

  function actualFrameRender()
  {
    sprGrp.draw();
  }

  // notes to self
  // account for different layers
  var playingAnim:Bool = false;
  var frameTickTypeShit:Float = 0;
  var animFrameRate:Int = 24;

  // redo all the matrix animation stuff

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.SPACE) playingAnim = !playingAnim;

    if (playingAnim)
    {
      frameTickTypeShit += elapsed;

      // prob fix this framerate thing for higher framerates?
      if (frameTickTypeShit >= 1 / 24)
      {
        changeFrame(1);
        frameTickTypeShit = 0;
        ParseAnimate.resetFrameList();
        ParseAnimate.parseTimeline(jsonAnim.AN.TL, 0, daFrame);

        generateSpriteShit();
      }
    }

    if (FlxG.keys.justPressed.RIGHT)
    {
      changeFrame(1);

      ParseAnimate.resetFrameList();
      ParseAnimate.parseTimeline(jsonAnim.AN.TL, 0, daFrame);

      generateSpriteShit();
    }
    if (FlxG.keys.justPressed.LEFT) changeFrame(-1);
  }

  /**
   * PARSES THE 'spritemap1.png' or whatever into a FlxAtlasFrames!!!
   */
  public static function fromAnimate(Source:FlxGraphicAsset, Description:String):FlxAtlasFrames
  {
    var graphic:FlxGraphic = FlxG.bitmap.add(Source);
    if (graphic == null) return null;

    var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(graphic);
    if (frames != null) return frames;

    if (graphic == null || Description == null) return null;

    frames = new FlxAtlasFrames(graphic);

    var data:Spritemap;

    var json:String = Description;

    // trace(json);

    var funnyJson:Dynamic = {};
    if (Assets.exists(json)) funnyJson = JaySon.parseFile(json);

    // trace(json);

    // data = c

    data = cast funnyJson;

    for (sprite in data.ATLAS.SPRITES)
    {
      // probably nicer way to do this? Oh well
      var swagSprite:Sprite = sprite.SPRITE;

      var rect = FlxRect.get(swagSprite.x, swagSprite.y, swagSprite.w, swagSprite.h);

      var size = new Rectangle(0, 0, rect.width, rect.height);

      var offset = FlxPoint.get(-size.left, -size.top);
      var sourceSize = FlxPoint.get(size.width, size.height);

      frames.addAtlasFrame(rect, sourceSize, offset, swagSprite.name);
    }

    return frames;
  }
}

// handy json function that has some hashlink fix, see the thing in CoolUtils file to see the link / where i stole it from
class JaySon
{
  public static function parseFile(name:String)
  {
    var cont = Assets.getText(name);
    function is(n:Int, what:Int)
      return cont.charCodeAt(n) == what;
    return JsonParser.parse(cont.substr(if (is(0, 65279)) /// looks like a HL target, skipping only first character here:
      1 else if (is(0, 239) && is(1, 187) && is(2, 191)) /// it seems to be Neko or PHP, start from position 3:
      3 else /// all other targets, that prepare the UTF string correctly
      0));
  }
}
