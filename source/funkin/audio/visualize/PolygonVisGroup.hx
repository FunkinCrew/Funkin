package funkin.audio.visualize;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;

@:nullSafety
class PolygonVisGroup extends FlxTypedGroup<PolygonSpectrogram>
{
  public var playerVis:Null<PolygonSpectrogram>;
  public var opponentVis:Null<PolygonSpectrogram>;
  public var instVis:Null<PolygonSpectrogram>;

  public function new()
  {
    super();
    playerVis = new PolygonSpectrogram();
    opponentVis = new PolygonSpectrogram();
  }

  /**
   * Adds the player's visualizer to the group.
   * @param visSnd The visualizer to add.
   */
  public function addPlayerVis(visSnd:FlxSound):Void
  {
    var vis:PolygonSpectrogram = new PolygonSpectrogram(visSnd);
    super.add(vis);
    playerVis = vis;
  }

  /**
   * Adds the opponent's visualizer to the group.
   * @param visSnd The visualizer to add.
   */
  public function addOpponentVis(visSnd:FlxSound):Void
  {
    var vis:PolygonSpectrogram = new PolygonSpectrogram(visSnd);
    super.add(vis);
    opponentVis = vis;
  }

  /**
   * Adds the instrument's visualizer to the group.
   * @param visSnd The visualizer to add.
   */
  public function addInstVis(visSnd:FlxSound):Void
  {
    var vis:PolygonSpectrogram = new PolygonSpectrogram(visSnd);
    super.add(vis);
    instVis = vis;
  }

  public function clearPlayerVis():Void
  {
    if (playerVis != null)
    {
      remove(playerVis);
      playerVis.destroy();
      playerVis = null;
    }
  }

  public function clearOpponentVis():Void
  {
    if (opponentVis != null)
    {
      remove(opponentVis);
      opponentVis.destroy();
      opponentVis = null;
    }
  }

  public function clearInstVis():Void
  {
    if (instVis != null)
    {
      remove(instVis);
      instVis.destroy();
      instVis = null;
    }
  }

  public function clearAllVis():Void
  {
    clearPlayerVis();
    clearOpponentVis();
    clearInstVis();
  }

  /**
   * Overrides the add function to add a visualizer to the group.
   * @param vis The visualizer to add.
   * @return The added visualizer.
   */
  override public function add(vis:PolygonSpectrogram):PolygonSpectrogram
  {
    var result:PolygonSpectrogram = super.add(vis);
    return result;
  }

  override public function destroy():Void
  {
    if (playerVis != null)
    {
      playerVis.destroy();
    }
    if (opponentVis != null)
    {
      opponentVis.destroy();
    }
    super.destroy();
  }
}
