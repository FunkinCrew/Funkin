package funkin.audio.visualize;

import funkin.audio.visualize.PolygonSpectogram;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;

class PolygonVisGroup extends FlxTypedGroup<PolygonSpectogram>
{
  var playerVis:PolygonSpectogram;
  var opponentVis:PolygonSpectogram;
  var instVis:PolygonSpectogram;

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
