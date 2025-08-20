package funkin.util.plugins;

#if FEATURE_NEWGROUNDS
import flixel.FlxBasic;
import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.text.FlxText;
import funkin.audio.FunkinSound;
import flixel.graphics.FlxGraphic;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.math.FlxRect;
import funkin.api.newgrounds.Medals;

@:nullSafety
class NewgroundsMedalPlugin extends FlxTypedContainer<FlxBasic>
{
  var medal:FlxAtlasSprite;
  var points:FlxText;
  var name:FlxText;

  public static var instance:Null<NewgroundsMedalPlugin> = null;

  var tween:Bool = false;

  var am:Float = 20;

  var funcs:Array<Void->Void> = [];

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

    medal = new FlxAtlasSprite(MEDAL_X, MEDAL_Y, Paths.animateAtlas("ui/medal"),
      {
        swfMode: true,
        cacheOnLoad: true
      });

    points = new FlxText(171 + MEDAL_X, 10 + MEDAL_Y, 50, 12, false);
    points.fieldHeight = 18;
    points.systemFont = "Arial";
    points.bold = true;
    points.italic = true;
    points.alignment = "right";

    points.text = "100";
    points.visible = false;
    points.scrollFactor.set();

    name = new FlxText(73 + MEDAL_X, 34 + MEDAL_Y, 0, 26);
    name.font = Paths.font("ShareTechMono-Regular.ttf");
    name.letterSpacing = -2;

    name.text = "Ono Boners Deluxe";

    name.clipRect = FlxRect.get(0, 0, 164, 35.2);

    name.visible = false;
    name.scrollFactor.set();

    medal.scrollFactor.set();
    medal.visible = false;

    medal.onAnimationPlay.add(function(animationName:String, loop:Bool) {
      switch (animationName)
      {
        case "show":
          points.visible = true;
          name.visible = true;
          if (name.width > name.clipRect.width)
          {
            @:nullSafety(Off)
            am = (name.text.length * (name.size + 2) * 1.25) / name.clipRect.width * 10;
            tween = true;
          }
        case "fade":
          FunkinSound.playOnce(Paths.sound('NGFadeOut'), 1.0);
        case "hide":
          points.visible = false;
          name.visible = false;
          tween = false;
          name.offset.x = 0;
          name.clipRect.x = 0;
          name.resetFrame();
          medal.replaceFrameGraphic(3, null);
      }
    });

    medal.onAnimationComplete.add(function(animationName:String) {
      switch (animationName)
      {
        case "show":
          medal.playAnimation("idle", false, false, true);
        case "fade":
          medal.playAnimation("hide");
      }
    });

    medal.onAnimationLoop.add(function(animationName:String) {
      if (animationName == "idle")
      {
        // check if the text has left the bounds of the atlas
        if (name.offset.x > medal.width)
        {
          medal.playAnimation("fade", true);
        }
      }
    });

    add(medal);
    add(points);
    add(name);

    FlxGraphic.defaultPersist = false;
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);
    if (tween)
    {
      var val = am * elapsed;
      name.offset.x += val;
      name.clipRect.x += val;
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
    instance.medal.onAnimationComplete.add(function(name:String) {
      if (instance.funcs.length > 0)
      {
        instance.funcs.shift()();
      }
    });
  }

  public static function play(points:Int = 100, name:String = "I LOVE CUM I LOVE CUM I LOVE CUM I LOVE CUM", ?graphic:FlxGraphic)
  {
    if (instance == null) return;
    var func = function() {
      instance.points.visible = false;
      instance.name.visible = false;
      instance.points.text = Std.string(points);
      instance.name.text = name;

      instance.medal.visible = true;
      instance.medal.replaceFrameGraphic(3, graphic);
      instance.medal.playAnimation("show");

      FunkinSound.playOnce(Paths.sound('NGFadeIn'), 1.0);
    }

    if (instance.medal.isAnimationFinished() && instance.funcs.length == 0) func();
    else
      instance.funcs.push(func);
  }
}
#end
