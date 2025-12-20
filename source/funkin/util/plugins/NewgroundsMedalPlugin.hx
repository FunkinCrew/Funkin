package funkin.util.plugins;

#if FEATURE_NEWGROUNDS
import flixel.FlxBasic;
import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.text.FlxText;
import funkin.audio.FunkinSound;
import flixel.graphics.FlxGraphic;
import funkin.graphics.FunkinSprite;
import flixel.math.FlxRect;
import funkin.api.newgrounds.Medals;
import funkin.util.macro.ConsoleMacro;
import funkin.ui.FullScreenScaleMode;

@:nullSafety
class NewgroundsMedalPlugin extends FlxTypedContainer<FlxBasic> implements ConsoleClass
{
  public static var instance:Null<NewgroundsMedalPlugin> = null;

  var medal:FunkinSprite;
  var points:FlxText;
  var name:FlxText;

  var moveText:Bool = false;
  var medalQueue:Array<Void->Void> = [];

  var textSpeed:Float = 20;

  final MEDAL_X = (FlxG.width - 250) * 0.5;
  final MEDAL_Y = FlxG.height - 100;

  public function new()
  {
    super();

    #if FLX_DEBUG
    FlxG.console.registerFunction("medal_test", NewgroundsMedalPlugin.play);
    FlxG.console.registerClass(Medals);
    #end

    FlxGraphic.defaultPersist = true;

    medal = FunkinSprite.createTextureAtlas((MEDAL_X) + (FullScreenScaleMode.gameCutoutSize.x / 2), MEDAL_Y, "ui/medal",
      {
        swfMode: true,
        filterQuality: HIGH
      });

    points = new FlxText((171 + MEDAL_X) + (FullScreenScaleMode.gameCutoutSize.x / 2), 17 + MEDAL_Y, 50, 12, false);
    points.fieldHeight = 18;
    points.systemFont = "Arial";
    points.bold = true;
    points.italic = true;
    points.alignment = "right";

    points.text = "100";
    points.visible = false;
    points.scrollFactor.set();

    name = new FlxText((73 + MEDAL_X) + (FullScreenScaleMode.gameCutoutSize.x / 2), 37 + MEDAL_Y, 0, 26);
    name.font = Paths.font("ShareTechMono-Regular.ttf");
    name.letterSpacing = -2;

    name.text = "Ono Boners Deluxe";
    name.clipRect = FlxRect.get(0, 0, 164, 35.2);

    name.visible = false;
    name.scrollFactor.set();

    medal.scrollFactor.set();
    medal.visible = false;

    medal.anim.onFrameLabel.add(function(label:String) {
      switch (label)
      {
        case "show":
          points.visible = true;
          name.visible = true;
          if (name.width > name.clipRect.width)
          {
            @:nullSafety(Off)
            textSpeed = (name.text.length * (name.size + 2) * 1.25) / name.clipRect.width * 10;
            moveText = true;
          }
        case "fade":
          FunkinSound.playOnce(Paths.sound('NGFadeOut'), 1.0);
        case "hide":
          points.visible = false;
          name.visible = false;
          moveText = false;
          name.offset.x = 0;
          name.clipRect.x = 0;
          name.resetFrame();
      }
    });

    medal.anim.onFinish.add(function(name:String) {
      medal.visible = false;
    });

    add(medal);
    add(points);
    add(name);

    FlxGraphic.defaultPersist = false;
  }

  /**
   * Update the positions of the medal atlas in case the resolution changes!
   */
  function updatePositions():Void
  {
    medal.x = MEDAL_X + (FullScreenScaleMode.gameCutoutSize.x / 2);
    points.x = (175 + MEDAL_X) + (FullScreenScaleMode.gameCutoutSize.x / 2);
    name.x = (79 + MEDAL_X) + (FullScreenScaleMode.gameCutoutSize.x / 2);
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);
    if (moveText)
    {
      var textX:Float = textSpeed * elapsed;

      name.offset.x += textX;
      name.clipRect.x += textX;
      name.resetFrame();
    }
  }

  public static function initialize()
  {
    FlxG.plugins.drawOnTop = true;
    instance = new NewgroundsMedalPlugin();
    FlxG.plugins.addPlugin(instance);

    // instance is defined above so there's no need to worry about null safety here
    @:nullSafety(Off)
    instance.medal.anim.onFinish.add(function(name:String) {
      if (instance.medalQueue.length > 0)
      {
        instance.medalQueue.shift()();
      }
    });
  }

  public static function play(points:Int = 100, name:String = "I LOVE CUM I LOVE CUM I LOVE CUM I LOVE CUM", ?graphic:FlxGraphic)
  {
    if (instance == null) return;

    var playMedal:Void->Void = function() {
      instance.points.visible = false;
      instance.name.visible = false;
      instance.points.text = Std.string(points);
      instance.name.text = name;
      instance.updatePositions();

      FunkinSound.playOnce(Paths.sound('NGFadeIn'), 1.0);
      instance.medal.anim.play("");

      instance.medal.visible = true;
      instance.medal.replaceSymbolGraphic("NGMEDAL", graphic);
    }

    if (instance.medal.isAnimationFinished() && instance.medalQueue.length == 0) playMedal();
    else
      instance.medalQueue.push(playMedal);
  }
}
#end
