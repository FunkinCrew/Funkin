package funkin.ui.freeplay;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.graphics.shaders.GaussianBlurShader;

/**
 * A FlxTypedGroup for capsules that does drawing in batches. This prevents memory leaks due to too many assets being rendered.
 */
@:nullSafety
class SongItemGroup extends FlxTypedGroup<SongMenuItem>
{
  var rankBlurredShader:GaussianBlurShader = new GaussianBlurShader(1);
  var favIconBlurredShader:GaussianBlurShader = new GaussianBlurShader(1.2);

  override function recycle(?cls:Class<SongMenuItem>, ?factory:Void->SongMenuItem, force:Bool = false, revive:Bool = true):SongMenuItem
  {
    var capsule:SongMenuItem = super.recycle(cls, factory, force, revive);

    // Apply the same shader instance to some elements so that we can use one draw call to render multiple of them.
    capsule.fakeBlurredRanking.shader = rankBlurredShader;
    capsule.blurredRanking.shader = rankBlurredShader;
    capsule.favIconBlurred.shader = favIconBlurredShader;

    return capsule;
  }

  @:access(flixel.FlxCamera)
  override function draw():Void
  {
    // Temporarily store the default cameras so we can replace them with the group's cameras.
    final oldDefaultCameras = FlxCamera._defaultCameras;
    if (_cameras != null)
    {
      FlxCamera._defaultCameras = _cameras;
    }

    final capsulesToRender:Array<SongMenuItem> = [];

    var hasTrail = false;
    for (capsule in this.members)
    {
      if (capsule != null && capsule.exists && capsule.visible)
      {
        if (capsule.hasTrail) hasTrail = true;
        capsulesToRender.push(capsule);
      }
    }

    if (capsulesToRender.length == 0) return;

    var firstCapsule = capsulesToRender[0];
    var memberCount:Int = firstCapsule.length;
    if (hasTrail && !firstCapsule.hasTrail) memberCount += 2;
    for (i in 0...memberCount)
    {
      for (capsule in capsulesToRender)
      {
        var member:FlxSprite = capsule.members[i];
        if (member == null || !member.visible || !member.alive) continue;

        member.draw();
      }
    }

    FlxCamera._defaultCameras = oldDefaultCameras;
  }
}
