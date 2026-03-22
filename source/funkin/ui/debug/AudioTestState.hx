package funkin.ui.debug;

import lime.media.effects.FilterEffect;

import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.FlxSprite;

class AudioTestState extends MusicBeatState
{
  var audio:FlxSound;
  var box:FlxSprite;
  var label:FlxText;
  var label2:FlxText;
  var filter:FilterEffect;
  var filterTypeNum:Int = 0;

  override function create():Void
  {
    super.create();

    label = new FlxText(0, 0, 0, "", 38);
    add(label);

    box = new FlxSprite(0, 0).makeGraphic(1, 1, 0xFFFFFFFF);
    add(box);

    label2 = new FlxText(0, FlxG.height * 0.5 + 200, 0, "", 24);
    add(label2);

    audio = FlxG.sound.load(Paths.music("chartEditorLoop/chartEditorLoop"));
    audio.addEffect(filter = new FilterEffect());

    lime.app.Application.current.window.onDropFile.add(onDropFile);

    audio.looped = true;
    audio.play();
  }

  private function numToFilterType(num:Int):FilterEffectType
  {
    return switch (num)
    {
      case 0: LOWPASS;
      case 1: HIGHPASS;
      case 2: BANDPASS;
      default: LOWPASS;
      //case 3: LOWSHELF;
      //case 4: HIGHSHELF;
      //case 5: PEAKING;
      //case 6: NOTCH;
      //default: LOWPASS;
    }
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.ESCAPE)
    {
      FlxG.switchState(() -> new funkin.ui.mainmenu.MainMenuState());
    }
    else if (FlxG.keys.justPressed.SPACE)
    {
      if (audio.playing) audio.pause();
      else audio.play();
    }

    if (FlxG.keys.justPressed.Q)
    {
      audio.time -= 1000;
    }
    else if (FlxG.keys.justPressed.W)
    {
      audio.time += 1000;
    }
    else if (FlxG.keys.justPressed.E)
    {
      audio.time = 0;
    }

    if (FlxG.keys.justPressed.A)
    {
      filterTypeNum--;
      if (filterTypeNum < 0) filterTypeNum = 2;
      filter.type = numToFilterType(filterTypeNum);
    }
    else if (FlxG.keys.justPressed.S)
    {
      filterTypeNum++;
      if (filterTypeNum > 2) filterTypeNum = 0;
      filter.type = numToFilterType(filterTypeNum);
    }
    else if (FlxG.keys.justPressed.D)
    {
      filter.type = numToFilterType(filterTypeNum = 0);
    }

    if (FlxG.keys.pressed.Z)
    {
      filter.frequency -= elapsed * (FlxG.keys.pressed.SHIFT ? 20000 : 10000);
    }
    else if (FlxG.keys.pressed.X)
    {
      filter.frequency += elapsed * (FlxG.keys.pressed.SHIFT ? 20000 : 10000);
    }
    else if (FlxG.keys.justPressed.C)
    {
      filter.frequency = 1000;
    }

    if (FlxG.keys.pressed.R)
    {
      audio.pan -= elapsed;
    }
    else if (FlxG.keys.pressed.T)
    {
      audio.pan += elapsed;
    }
    else if (FlxG.keys.justPressed.Y)
    {
      audio.pan = 0;
    }

    if (FlxG.keys.pressed.F)
    {
      audio.volume -= elapsed;
    }
    else if (FlxG.keys.pressed.G)
    {
      audio.volume += elapsed;
    }
    else if (FlxG.keys.justPressed.H)
    {
      audio.volume = 1;
    }

    if (FlxG.keys.pressed.V)
    {
      audio.pitch -= elapsed;
    }
    else if (FlxG.keys.pressed.B)
    {
      audio.pitch += elapsed;
    }
    else if (FlxG.keys.justPressed.N)
    {
      audio.pitch = 1;
    }

    var peak = audio.amplitude;

    box.scale.set(200, peak * 400);
    box.updateHitbox();
    box.setPosition((FlxG.width - 200) * 0.5, FlxG.height * 0.5 + 180 - box.scale.y);

    //label.text = "Time Position: " + FlxMath.roundDecimal(audio.time / 1000, 2);
    //label.screenCenter();
    //label.y -= 90;

    label2.text = "Frequency: " + filter.frequency + ", Type: " + (cast filter.type);
    label2.screenCenter(X);
  }

  function onDropFile(#if (js && html5) _path:String #else path:String #end, source:String, x:Float, y:Float):Void
  {
    #if (js && html5)
    var fileReader = new js.html.FileReader();
    var file = untyped _path;

    fileReader.onload = function(data) {
      audio.loadEmbedded(openfl.media.Sound.fromAudioBuffer(lime.media.AudioBuffer.fromBase64(untyped fileReader.result)));
      audio.looped = true;
      audio.play();
    };

    fileReader.readAsDataURL(file);
    trace(untyped file.name);
    #else
    audio.unload();
    audio.data?.destroy();

    trace(path);

    audio.loadEmbedded(path);
    audio.looped = true;
    audio.play();
    #end
  }
}