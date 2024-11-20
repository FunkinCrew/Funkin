import flixel.FlxSprite;
import flixel.group.FlxTypedSpriteGroup;

class ABotVisualizer extends FlxTypedSpriteGroup
{
  function new()
  {
    super(0, 0);

    var vizFrames = Paths.getSparrowAtlas('aBotViz');

    for (i in 1...8)
    {
      var viz:FlxSprite = new FlxSprite(50 * i, 0);
      viz.frames = vizFrames;
      add(viz);

      // note: in the a-bot files, dave named the symbols both "VIZ" and "viz"
      // I manually changed them in the xml file, but if it ever gets re-exported
      // it will need to either be renamed, or accomodated here!
      viz.animation.addByPrefix('VIZ', "viz" + i, 0);
      viz.animation.play("VIZ", false, false, 3);
    }
  }
}
