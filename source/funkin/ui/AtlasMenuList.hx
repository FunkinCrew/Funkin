package funkin.ui;

import flixel.graphics.frames.FlxAtlasFrames;
import funkin.ui.MenuList;

typedef AtlasAsset = flixel.util.typeLimit.OneOfTwo<String, FlxAtlasFrames>;

/**
 * A menulist whose items share a single texture atlas.
 */
class AtlasMenuList extends MenuTypedList<AtlasMenuItem>
{
  public var atlas:FlxAtlasFrames;

  public function new(atlas, navControls:NavControls = Vertical, ?wrapMode)
  {
    super(navControls, wrapMode);

    if (Std.isOfType(atlas, String)) this.atlas = Paths.getSparrowAtlas(cast atlas);
    else
      this.atlas = cast atlas;
  }

  public function createItem(x = 0.0, y = 0.0, name, callback, fireInstantly = false)
  {
    var item = new AtlasMenuItem(x, y, name, atlas, callback);
    item.fireInstantly = fireInstantly;
    return addItem(name, item);
  }

  override function destroy()
  {
    super.destroy();
    atlas = null;
  }
}

/**
 * A menu list item which uses single texture atlas.
 */
class AtlasMenuItem extends MenuListItem
{
  var atlas:FlxAtlasFrames;

  public var centered:Bool = false;

  public function new(x = 0.0, y = 0.0, name:String, atlas, callback)
  {
    this.atlas = atlas;
    super(x, y, name, callback);
  }

  override function setData(name:String, ?callback:Void->Void)
  {
    frames = atlas;
    animation.addByPrefix('idle', '$name idle', 24);
    animation.addByPrefix('selected', '$name selected', 24);

    super.setData(name, callback);
  }

  public function changeAnim(animName:String)
  {
    animation.play(animName);
    updateHitbox();

    if (centered)
    {
      // position by center
      centerOrigin();
      offset.copyFrom(origin);
    }
  }

  override function idle()
  {
    changeAnim('idle');
  }

  override function select()
  {
    changeAnim('selected');
  }

  override function get_selected()
  {
    return animation.curAnim != null && animation.curAnim.name == "selected";
  }

  override function destroy()
  {
    super.destroy();
    atlas = null;
  }
}
