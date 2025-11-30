package funkin.ui.charSelect;

import funkin.graphics.FunkinSprite;
import funkin.modding.IScriptedClass.IBPMSyncedScriptedClass;
import funkin.modding.events.ScriptEvent;
import funkin.vis.dsp.SpectralAnalyzer;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.ui.FullScreenScaleMode;
import flixel.math.FlxPoint;

@:nullSafety
class CharSelectGF extends FunkinSprite implements IBPMSyncedScriptedClass
{
  var analyzer:Null<SpectralAnalyzer>;
  var analyzerLevelsCache:Array<Bar> = new Array<Bar>();

  var currentGFPath:String = "";
  var enableVisualizer:Bool = false;

  var danceEvery:Int = 2;

  public function new(x:Float, y:Float)
  {
    super(x, y);
    this.applyStageMatrix = true;

    switchGF(Constants.DEFAULT_CHARACTER);
  }

  public function onStepHit(event:SongTimeScriptEvent):Void {}

  public function onBeatHit(event:SongTimeScriptEvent):Void
  {
    // TODO: There's a minor visual bug where there's a little stutter.
    // This happens because the animation is getting restarted while it's already playing.
    // I tried make this not interrupt an existing idle,
    // but isAnimationFinished() and isLoopComplete() both don't work! What the hell?
    // danceEvery isn't necessary if that gets fixed.
    if (getCurrentAnimation() == "idle" && (event.beat % danceEvery == 0))
    {
      trace('GF beat hit');
      anim.play("idle", true);
    }
  };

  override public function draw()
  {
    if (analyzer != null) drawFFT();
    super.draw();
  }

  function drawFFT()
  {
    if (enableVisualizer && analyzer != null)
    {
      analyzerLevelsCache = analyzer.getLevels(analyzerLevelsCache);
      var frame:Null<animate.internal.Frame> = this.timeline.getLayer("VIZ_bars")?.getFrameAtIndex(anim.curAnim.curFrame) ?? null;
      var elements:Array<animate.internal.elements.Element> = frame?.elements ?? [];
      var len:Int = cast Math.min(elements.length, 7);

      for (i in 0...len)
      {
        var animFrame:Int = (FlxG.sound.volume == 0 || FlxG.sound.muted) ? 0 : Math.round(analyzerLevelsCache[i].value * 12);

        #if sys
        // Web version scales with the Flixel volume level.
        // This line brings platform parity but looks worse.
        // animFrame = Math.round(animFrame * FlxG.sound.volume);
        #end

        animFrame = Math.floor(Math.min(12, animFrame));
        animFrame = Math.floor(Math.max(0, animFrame));

        animFrame = Std.int(Math.abs(animFrame - 12)); // shitty dumbass flip, cuz dave got da shit backwards lol!

        var convertedSymbol = elements[i].toSymbolInstance();
        convertedSymbol.firstFrame = animFrame;

        elements[i] = convertedSymbol;
      }
    }
  }

  /**
   * For switching between "GFs" such as gf, nene, etc
   * @param bf Which BF we are selecting, so that we know the accompyaning GF
   */
  public function switchGF(bf:String):Void
  {
    var previousGFPath:String = currentGFPath;

    var bfObj = PlayerRegistry.instance.fetchEntry(bf);
    var gfData = bfObj?.getCharSelectData()?.gf;
    var assetPath:Null<String> = gfData?.assetPath ?? "";

    currentGFPath = assetPath;

    // We don't need to update any anims if we didn't change GF
    trace('currentGFPath(${currentGFPath})');
    if (currentGFPath == "")
    {
      this.visible = false;
      return;
    }
    else if (previousGFPath != currentGFPath)
    {
      this.visible = true;

      var path:String = currentGFPath;
      var texture:Null<animate.FlxAnimateFrames> = CharSelectAtlasHandler.loadAtlas(path, {swfMode: true});
      if (texture != null)
      {
        frames = texture;
      }
      else
      {
        this.visible = false;
        currentGFPath = "";
        return;
      }

      enableVisualizer = gfData?.visualizer ?? false;
    }

    anim.play("idle", true);

    updateHitbox();
  }

  public function onScriptEvent(event:ScriptEvent):Void {};

  public function onCreate(event:ScriptEvent):Void {};

  public function onDestroy(event:ScriptEvent):Void {};

  public function onUpdate(event:UpdateScriptEvent):Void {};
}
