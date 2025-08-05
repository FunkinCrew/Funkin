package funkin.ui.charSelect;

import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.math.FlxMath;
import funkin.util.FramesJSFLParser;
import funkin.util.FramesJSFLParser.FramesJSFLInfo;
import funkin.util.FramesJSFLParser.FramesJSFLFrame;
import funkin.modding.IScriptedClass.IBPMSyncedScriptedClass;
import funkin.modding.events.ScriptEvent;
import funkin.vis.dsp.SpectralAnalyzer;
import funkin.data.freeplay.player.PlayerRegistry;

class CharSelectGF extends FlxAtlasSprite implements IBPMSyncedScriptedClass
{
  var fadeTimer:Float = 0;
  var fadingStatus:FadeStatus = OFF;
  var fadeAnimIndex:Int = 0;

  var animInInfo:Null<FramesJSFLInfo>;
  var animOutInfo:Null<FramesJSFLInfo>;

  var intendedYPos:Float = 0;
  var intendedAlpha:Float = 0;
  var list:Array<String> = [];

  var analyzer:SpectralAnalyzer;

  var currentGFPath:Null<String>;
  var enableVisualizer:Bool = false;

  public function new()
  {
    super(0, 0, Paths.animateAtlas("charSelect/gfChill"));

    list = anim.curSymbol.getFrameLabelNames();

    switchGF("bf");
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    switch (fadingStatus)
    {
      case OFF:
        // do nothing if it's off!
        // or maybe force position to be 0,0?
        // maybe reset timers?
        resetFadeAnimParams();
      case FADE_OUT:
        doFade(animOutInfo);
      case FADE_IN:
        doFade(animInInfo);
      default:
    }
  }

  public function onStepHit(event:SongTimeScriptEvent):Void {}

  var danceEvery:Int = 2;

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
      playAnimation("idle", true, false, false);
    }
  };

  override public function draw()
  {
    if (analyzer != null) drawFFT();
    super.draw();
  }

  function drawFFT()
  {
    if (enableVisualizer)
    {
      var levels = analyzer.getLevels();
      var frame = anim.curSymbol.timeline.get("VIZ_bars").get(anim.curFrame);
      var elements = frame.getList();
      var len:Int = cast Math.min(elements.length, 7);

      for (i in 0...len)
      {
        var animFrame:Int = (FlxG.sound.volume == 0 || FlxG.sound.muted) ? 0 : Math.round(levels[i].value * 12);

        #if sys
        // Web version scales with the Flixel volume level.
        // This line brings platform parity but looks worse.
        // animFrame = Math.round(animFrame * FlxG.sound.volume);
        #end

        animFrame = Math.floor(Math.min(12, animFrame));
        animFrame = Math.floor(Math.max(0, animFrame));

        animFrame = Std.int(Math.abs(animFrame - 12)); // shitty dumbass flip, cuz dave got da shit backwards lol!

        elements[i].symbol.firstFrame = animFrame;
      }
    }
  }

  /**
   * @param animInfo Should not be confused with animInInfo!
   *                 This is merely a local var for the function!
   */
  function doFade(animInfo:Null<FramesJSFLInfo>):Void
  {
    if (animInfo == null)
    {
      return;
    }

    fadeTimer += FlxG.elapsed;
    if (fadeTimer >= 1 / 24)
    {
      fadeTimer -= FlxG.elapsed;
      // only inc the index for the first frame, used for reference of where to "start"
      if (fadeAnimIndex == 0)
      {
        fadeAnimIndex++;
        return;
      }

      var curFrame:FramesJSFLFrame = animInfo.frames[fadeAnimIndex];
      var prevFrame:FramesJSFLFrame = animInfo.frames[fadeAnimIndex - 1];

      var xDiff:Float = curFrame.x - prevFrame.x;
      var yDiff:Float = curFrame.y - prevFrame.y;
      var alphaDiff:Float = curFrame.alpha - prevFrame.alpha;
      alphaDiff /= 100; // flash exports alpha as a whole number

      alpha += alphaDiff;
      alpha = FlxMath.bound(alpha, 0, 1);
      x += xDiff;
      y += yDiff;

      fadeAnimIndex++;
    }

    if (fadeAnimIndex >= animInfo.frames.length) fadingStatus = OFF;
  }

  function resetFadeAnimParams()
  {
    fadeTimer = 0;
    fadeAnimIndex = 0;
  }

  /**
   * For switching between "GFs" such as gf, nene, etc
   * @param bf Which BF we are selecting, so that we know the accompyaning GF
   */
  public function switchGF(bf:String):Void
  {
    var previousGFPath = currentGFPath;

    var bfObj = PlayerRegistry.instance.fetchEntry(bf);
    var gfData = bfObj?.getCharSelectData()?.gf;
    currentGFPath = gfData?.assetPath != null ? Paths.animateAtlas(gfData?.assetPath) : null;

    // We don't need to update any anims if we didn't change GF
    trace('currentGFPath(${currentGFPath})');
    if (currentGFPath == null)
    {
      this.visible = false;
      return;
    }
    else if (previousGFPath != currentGFPath)
    {
      this.visible = true;
      loadAtlas(currentGFPath);

      enableVisualizer = gfData?.visualizer ?? false;

      var animInfoPath = Paths.file('images/${gfData?.animInfoPath}');

      animInInfo = FramesJSFLParser.parse(animInfoPath + '/In.txt');
      animOutInfo = FramesJSFLParser.parse(animInfoPath + '/Out.txt');

      if (animInInfo == null) trace("[ERROR] Failed to load data for animInInfo, is the path provided correct?");
      if (animOutInfo == null) trace("[ERROR] Failed to load data for animOutInfo, is the path provided correct?");
    }

    playAnimation("idle", true, false, false);

    updateHitbox();
  }

  public function onScriptEvent(event:ScriptEvent):Void {};

  public function onCreate(event:ScriptEvent):Void {};

  public function onDestroy(event:ScriptEvent):Void {};

  public function onUpdate(event:UpdateScriptEvent):Void {};
}

enum FadeStatus
{
  OFF;
  FADE_OUT;
  FADE_IN;
}
