package funkin.play.notes.notesound;

import funkin.audio.FunkinSound;

/// Class that handles playing note hit sounds
class NoteSoundPlayer
{
  var sound:FunkinSound = null;

  public function new() {}

  /// Should be called to play the hit sound, or additionally start a sustain "roll" sound if `sustain` is true
  public function begin(sustain:Bool):Void
  {
    if (Preferences.noteSoundType == NoteSoundType.None) return;

    final folderPath:String = 'noteSounds/${Preferences.noteSoundType}';
    final noteType:String = (sustain && Assets.exists(Paths.sound('${folderPath}/beginSustain'))) ? "beginSustain" : "begin";
    final volume:Float = Preferences.noteSoundVolume / 100.0;

    // TODO: Add support for sustain notes and play them here
    // also note that in "how to.txt" there is some text saying sustain sounds aren't implemented yet
    if (sound != null && sound.isPlaying) sound.destroy();
    sound = FunkinSound.load(Paths.sound('${folderPath}/${noteType}'), volume, false, true);
    sound.play(true);
  }

  /// Should be called to stop sustain note "roll" sounds
  public function end(sustain:Bool):Void
  {
    // Doesn't currently get called anywhere, not sure where to call this from
  }
}
