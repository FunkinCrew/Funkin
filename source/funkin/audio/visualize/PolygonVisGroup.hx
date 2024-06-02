package funkin.audio.visualize;

import funkin.audio.visualize.PolygonSpectogram;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;

class PolygonVisGroup extends FlxTypedGroup<PolygonSpectogram>
{
  public var playerVis:PolygonSpectogram;
  public var opponentVis:PolygonSpectogram;
  public var instVis:PolygonSpectogram;

  public function new()
  {
    super();
    playerVis = new PolygonSpectogram();
    opponentVis = new PolygonSpectogram();
  }

  /**
   * Adds the player's visualizer to the group.
   * @param visSnd The visualizer to add.
   */
  public function addPlayerVis(visSnd:FlxSound):Void
  {
    var vis:PolygonSpectogram = new PolygonSpectogram(visSnd);
    super.add(vis);
    playerVis = vis;
  }

  /**
   * Adds the opponent's visualizer to the group.
   * @param visSnd The visualizer to add.
   */
  public function addOpponentVis(visSnd:FlxSound):Void
  {
    var vis:PolygonSpectogram = new PolygonSpectogram(visSnd);
    super.add(vis);
    opponentVis = vis;
  }

  /**
   * Adds the instrument's visualizer to the group.
   * @param visSnd The visualizer to add.
   */
  public function addInstVis(visSnd:FlxSound):Void
  {
    var vis:PolygonSpectogram = new PolygonSpectogram(visSnd);
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
  public override function add(vis:PolygonSpectogram):PolygonSpectogram
  {
    var result:PolygonSpectogram = super.add(vis);
    return result;
  }

  public override function destroy():Void
  {
    playerVis.destroy();
    opponentVis.destroy();
    super.destroy();
  }
}
