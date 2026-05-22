package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import flixel.FlxSprite;
import funkin.play.event.PlayAnimationSongEvent;
import haxe.ui.events.UIEvent;

/**
 * Properties-panel container for `PlayAnimation` song events.
 *
 * Target field is a dropdown discovered from the loaded stage:
 *   - Three canonical character roles (Boyfriend / Dad / Girlfriend), each
 *     listed only when the stage actually has that character.
 *   - Every named prop from `currentStage.namedProps`.
 * Animation field is a dropdown discovered from the resolved target sprite's
 * `animation.getNameList()`. Refreshes when the target changes.
 *
 * Unknown current values (aliases like `bf`/`gf`, modded prop names, or anims
 * from a different character) are preserved as stray entries so a round-trip
 * through the camera editor never silently loses data.
 *
 * Force stays a `CheckBox`.
 *
 * No ease preview, no `duration` field — base's `getEasePreview()` default
 * `null` makes `destroy()` a no-op.
 */
@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/ui/editors/camera-editor/components/properties/play-animation.xml'))
class PlayAnimationContainer extends BaseEventContainer
{
  public function new(state:CameraEditorState)
  {
    super(state);
    bindBoolField(playAnimationForce, 'force');
  }

  /**
   * Populate UI controls from the currently-selected event.
   */
  public function loadCurrentEventData():Void
  {
    final selected = cameraEditorState.selectedSongEvent;
    if (selected == null) return;

    final currentTarget:String = selected.getString('target') ?? PlayAnimationSongEvent.DEFAULT_TARGET;
    final currentAnim:String = selected.getString('anim') ?? PlayAnimationSongEvent.DEFAULT_ANIM;

    playAnimationTarget.pauseEvent(UIEvent.CHANGE, true);
    playAnimationAnim.pauseEvent(UIEvent.CHANGE, true);

    populateTargetDropdown(currentTarget);
    selectStringItem(playAnimationTarget, currentTarget);

    populateAnimDropdown(currentTarget, currentAnim);
    selectStringItem(playAnimationAnim, currentAnim);

    loadBoolField(playAnimationForce, 'force', PlayAnimationSongEvent.DEFAULT_FORCE);

    playAnimationTarget.resumeEvent(UIEvent.CHANGE, true, true);
    playAnimationAnim.resumeEvent(UIEvent.CHANGE, true, true);

    updateCameraPreview();
  }

  /**
   * Called when the Target dropdown changes. Writes the new value, rebuilds
   * the Animation dropdown for that target, and tries to preserve the
   * previously-selected animation.
   */
  @:bind(playAnimationTarget, UIEvent.CHANGE)
  function onChange_playAnimationTarget(_:UIEvent):Void
  {
    final selected = cameraEditorState.selectedSongEvent;
    if (selected == null) return;
    if (playAnimationTarget.selectedItem == null) return;

    final newTarget:String = Std.string(playAnimationTarget.selectedItem.id);
    selected.set('target', newTarget);

    final currentAnim:String = selected.getString('anim') ?? PlayAnimationSongEvent.DEFAULT_ANIM;

    final newTargetSprite:Null<FlxSprite> = resolveTarget(newTarget);
    final animList:Array<String> = (newTargetSprite != null
      && newTargetSprite.animation != null) ? newTargetSprite.animation.getNameList() : [];

    var animToUse:String = currentAnim;
    if (animList.length > 0 && !animList.contains(currentAnim))
    {
      animToUse = PlayAnimationSongEvent.DEFAULT_ANIM;
      selected.set('anim', animToUse);
    }

    playAnimationAnim.pauseEvent(UIEvent.CHANGE, true);
    populateAnimDropdown(newTarget, animToUse);
    selectStringItem(playAnimationAnim, animToUse);
    playAnimationAnim.resumeEvent(UIEvent.CHANGE, true, true);

    updateCameraPreview();
  }

  /**
   * Called when the Animation dropdown changes. Writes the new value.
   */
  @:bind(playAnimationAnim, UIEvent.CHANGE)
  function onChange_playAnimationAnim(_:UIEvent):Void
  {
    final selected = cameraEditorState.selectedSongEvent;
    if (selected == null) return;
    if (playAnimationAnim.selectedItem == null) return;

    final newAnim:String = Std.string(playAnimationAnim.selectedItem.id);
    selected.set('anim', newAnim);

    updateCameraPreview();
  }

  /**
   * Rebuild the target dropdown's dataSource from the loaded stage.
   * `currentTarget` is preserved as a stray entry if not in the canonical list.
   */
  function populateTargetDropdown(currentTarget:String):Void
  {
    playAnimationTarget.dataSource.clear();

    final stage = cameraEditorState.currentStage;
    if (stage != null)
    {
      final bf = stage.getBoyfriend();
      if (bf != null) playAnimationTarget.dataSource.add({id: 'boyfriend', text: labelWithAnimCount(bf.characterName ?? 'Boyfriend', bf)});
      final dad = stage.getDad();
      if (dad != null) playAnimationTarget.dataSource.add({id: 'dad', text: labelWithAnimCount(dad.characterName ?? 'Dad', dad)});
      final gf = stage.getGirlfriend();
      if (gf != null) playAnimationTarget.dataSource.add({id: 'girlfriend', text: labelWithAnimCount(gf.characterName ?? 'Girlfriend', gf)});

      @:privateAccess
      for (propName in stage.namedProps.keys())
      {
        playAnimationTarget.dataSource.add({id: propName, text: labelWithAnimCount(propName, stage.getNamedProp(propName))});
      }
    }

    addStringItemIfMissing(playAnimationTarget, currentTarget);
  }

  /**
   * Format a target dropdown label with its animation count,
   * e.g. `"Girlfriend (4 animations)"` / `"spookyTree (1 animation)"`.
   */
  static function labelWithAnimCount(name:String, target:Null<FlxSprite>):String
  {
    final count:Int = (target != null && target.animation != null) ? target.animation.getNameList().length : 0;
    return '$name (${count} ${count == 1 ? 'animation' : 'animations'})';
  }

  /**
   * Rebuild the animation dropdown's dataSource from the target sprite.
   * `currentAnim` is preserved as a stray entry if not in the resolved list.
   */
  function populateAnimDropdown(targetName:String, currentAnim:String):Void
  {
    playAnimationAnim.dataSource.clear();

    final target:Null<FlxSprite> = resolveTarget(targetName);
    final animList:Array<String> = (target != null
      && target.animation != null) ? target.animation.getNameList() : [];

    // A stray value (a modded/aliased anim not present on the resolved target) must stay
    // visible and selectable so the round-trip never silently loses it. Only fall back to
    // the disabled "None" display when there's nothing worth preserving (the plain default).
    final hasStrayAnim:Bool = currentAnim != null
      && currentAnim != ''
      && currentAnim != PlayAnimationSongEvent.DEFAULT_ANIM
      && !animList.contains(currentAnim);

    if (target != null && animList.length == 0 && !hasStrayAnim)
    {
      playAnimationAnim.text = 'None';
      playAnimationAnim.disabled = true;
      return;
    }

    playAnimationAnim.disabled = false;

    for (animName in animList)
    {
      playAnimationAnim.dataSource.add({id: animName, text: animName});
    }

    addStringItemIfMissing(playAnimationAnim, currentAnim);
  }

  /**
   * Resolve a target string to its FlxSprite via the same dispatcher used
   * by `PlayAnimationSongEvent.handleEvent` and
   * `CameraEditorState.handlePlayAnimationEvent`.
   * Returns null if the stage isn't loaded or the target string doesn't match.
   */
  function resolveTarget(targetName:String):Null<FlxSprite>
  {
    final stage = cameraEditorState.currentStage;
    if (stage == null) return null;

    return switch (targetName)
    {
      case 'boyfriend' | 'bf' | 'player': stage.getBoyfriend();
      case 'dad' | 'opponent': stage.getDad();
      case 'girlfriend' | 'gf': stage.getGirlfriend();
      default: stage.getNamedProp(targetName);
    };
  }

  /**
   * Add `{id: value, text: value}` to a dropdown's dataSource iff no entry
   * with matching `id` already exists. Used for preserving stray values
   * (aliases, typos, mod targets) so round-tripping never loses data.
   */
  static function addStringItemIfMissing(dropdown:haxe.ui.components.DropDown, value:String):Void
  {
    if (value == null || value == '') return;
    for (i in 0...dropdown.dataSource.size)
    {
      final item:Dynamic = dropdown.dataSource.get(i);
      if (item != null && item.id == value) return;
    }
    dropdown.dataSource.add({id: value, text: value});
  }

  /**
   * Select the dropdown item whose `id` matches `value`. No-op if not found.
   */
  static function selectStringItem(dropdown:haxe.ui.components.DropDown, value:String):Void
  {
    if (value == null) return;
    dropdown.selectItemBy(function(item):Bool {
      return item != null && item.id == value;
    });
  }
}
#end
