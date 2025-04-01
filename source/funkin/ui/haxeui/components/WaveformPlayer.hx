package funkin.ui.haxeui.components;

import funkin.audio.waveform.WaveformSprite;
import funkin.audio.waveform.WaveformData;
import haxe.ui.backend.flixel.components.SpriteWrapper;

class WaveformPlayer extends SpriteWrapper
{
  public var waveform(default, null):WaveformSprite;

  public function new(?waveformData:WaveformData)
  {
    super();
    this.waveform = new WaveformSprite(waveformData);
    this.sprite = waveform;
  }
}
