package funkin.ui.debug.stageeditor.toolboxes;

import haxe.ui.components.NumberStepper;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.character.CharacterData;
import funkin.util.SortUtil;
import funkin.save.Save;
import haxe.ui.components.Button;
import haxe.ui.components.Slider;
import haxe.ui.containers.menus.Menu;
import haxe.ui.core.Screen;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import haxe.ui.containers.Grid;
import haxe.ui.events.UIEvent;

using StringTools;

@:access(funkin.ui.debug.stageeditor.StageEditorState)
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/toolboxes/character-properties.xml"))
class StageEditorCharacterToolbox extends StageEditorDefaultToolbox
{
  public var charPosX:NumberStepper;
  public var charPosY:NumberStepper;
  public var charZIdx:NumberStepper;
  public var charScale:NumberStepper;
  public var charCamX:NumberStepper;
  public var charCamY:NumberStepper;
  public var charAlpha:NumberStepper;
  public var charAngle:NumberStepper;
  public var charScrollX:NumberStepper;
  public var charScrollY:NumberStepper;

  var charType:Button;
  var charMenu:StageEditorCharacterMenu;

  override public function new(state:StageEditorState)
  {
    super(state);

    // Numeric callbacks.
    charPosX.onChange = charPosY.onChange = function(_) {
      repositionCharacter();
    }

    charZIdx.max = StageEditorState.MAX_Z_INDEX;
    charZIdx.onChange = function(_) {
      state.charGroups[state.selectedChar.characterType].zIndex = Std.int(charZIdx.pos);
      state.sortAssets();
    }

    charCamX.onChange = charCamY.onChange = function(_) {
      state.charCamOffsets[state.selectedChar.characterType] = [charCamX.pos, charCamY.pos];
      state.updateMarkerPos();
    }

    charScale.onChange = function(_) {
      state.selectedChar.setScale(state.selectedChar.getBaseScale() * charScale.pos);
      repositionCharacter();
    }

    charAlpha.onChange = function(_) {
      state.selectedChar.alpha = charAlpha.pos;
    }

    charAngle.onChange = function(_) {
      state.selectedChar.angle = charAngle.pos;
    }

    charScrollX.onChange = charScrollY.onChange = function(_) {
      state.selectedChar.scrollFactor.set(charScrollX.pos, charScrollY.pos);
    }

    // character button
    charType.onClick = function(_) {
      charMenu = new StageEditorCharacterMenu(state, this);
      Screen.instance.addComponent(charMenu);
    }

    refresh();

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    stageEditorState.menubarItemWindowCharacter.selected = false;
  }

  override public function refresh()
  {
    var name = stageEditorState.selectedChar.characterType;
    var curChar = stageEditorState.selectedChar;

    charPosX.step = charPosY.step = stageEditorState.moveStep;
    charCamX.step = charCamY.step = stageEditorState.moveStep;
    charAngle.step = funkin.save.Save.instance.stageEditorAngleStep;

    // Always update the displays, since selectedChar is never null.

    if (charPosX.pos != stageEditorState.charPos[name][0]) charPosX.pos = stageEditorState.charPos[name][0];
    if (charPosY.pos != stageEditorState.charPos[name][1]) charPosY.pos = stageEditorState.charPos[name][1];
    if (charZIdx.pos != stageEditorState.charGroups[name].zIndex) charZIdx.pos = stageEditorState.charGroups[name].zIndex;
    if (charCamX.pos != stageEditorState.charCamOffsets[name][0]) charCamX.pos = stageEditorState.charCamOffsets[name][0];
    if (charCamY.pos != stageEditorState.charCamOffsets[name][1]) charCamY.pos = stageEditorState.charCamOffsets[name][1];
    if (charScale.pos != curChar.scale.x / curChar.getBaseScale()) charScale.pos = curChar.scale.x / curChar.getBaseScale();
    if (charAlpha.pos != curChar.alpha) charAlpha.pos = curChar.alpha;
    if (charAngle.pos != curChar.angle) charAngle.pos = curChar.angle;
    if (charScrollX.pos != curChar.scrollFactor.x) charScrollX.pos = curChar.scrollFactor.x;
    if (charScrollY.pos != curChar.scrollFactor.y) charScrollY.pos = curChar.scrollFactor.y;

    var prevText = charType.text;
    var charData = CharacterDataParser.fetchCharacterData(curChar.characterId);
    charType.icon = (charData == null ? null : CharacterDataParser.getCharPixelIconAsset(curChar.characterId));
    charType.text = (charData == null ? "None" : charData.name.length > 6 ? '${charData.name.substr(0, 6)}.' : '${charData.name}');

    if (prevText != charType.text) Screen.instance.removeComponent(charMenu);
  }

  public function repositionCharacter()
  {
    stageEditorState.selectedChar.x = charPosX.pos - stageEditorState.selectedChar.characterOrigin.x + stageEditorState.selectedChar.globalOffsets[0];
    stageEditorState.selectedChar.y = charPosY.pos - stageEditorState.selectedChar.characterOrigin.y + stageEditorState.selectedChar.globalOffsets[1];

    stageEditorState.selectedChar.setScale(stageEditorState.selectedChar.getBaseScale() * charScale.pos);
    stageEditorState.updateMarkerPos();
  }
}

@:xml('
<menu id="iconSelector" width="410" height="185" padding="8">
  <vbox width="100%" height="100%">
    <scrollview id="charSelectScroll" width="390" height="150" contentWidth="100%" />
    <label id="charIconName" text="(choose a character)" />
  </vbox>
</menu>
')
class StageEditorCharacterMenu extends Menu // copied from chart editor
{
  override public function new(state:StageEditorState, parent:StageEditorCharacterToolbox)
  {
    super();

    this.x = Screen.instance.currentMouseX;
    this.y = Screen.instance.currentMouseY;

    var charGrid = new Grid();
    charGrid.columns = 5;
    charGrid.width = this.width;
    charSelectScroll.addComponent(charGrid);

    var charIds = CharacterDataParser.listCharacterIds();
    charIds.sort(SortUtil.alphabetically);

    var defaultText:String = '(choose a character)';

    for (charIndex => charId in charIds)
    {
      var charData:CharacterData = CharacterDataParser.fetchCharacterData(charId);

      var charButton = new Button();
      charButton.width = 70;
      charButton.height = 70;
      charButton.padding = 8;
      charButton.iconPosition = "top";

      if (charId == state.selectedChar.characterId)
      {
        // Scroll to the character if it is already selected.
        charSelectScroll.hscrollPos = Math.floor(charIndex / 5) * 80;
        charButton.selected = true;

        defaultText = '${charData.name} [${charId}]';
      }

      var LIMIT = 6;
      charButton.icon = CharacterDataParser.getCharPixelIconAsset(charId);
      charButton.text = charData.name.length > LIMIT ? '${charData.name.substr(0, LIMIT)}.' : '${charData.name}';

      charButton.onClick = _ -> {
        var type = state.selectedChar.characterType;
        if (state.selectedChar.characterId == charId) return; // saves on memory

        var group = state.charGroups[type];
        group.killMembers();
        for (member in group.members)
        {
          member.kill();
          group.remove(member, true);
          member.destroy();
        }
        group.clear();

        // okay i think that was enough cleaning phew you can see how clean this group is now!!!
        // anyways new character!!!!

        var newChar = CharacterDataParser.fetchCharacter(charId, true);
        if (newChar == null)
        {
          state.notifyChange("Switch Character", "Couldn't find character " + charId + ". Switching to default.", true);
          newChar = CharacterDataParser.fetchCharacter(Constants.DEFAULT_CHARACTER, true);
        }

        newChar.characterType = type;

        newChar.resetCharacter(true);
        newChar.flipX = type == CharacterType.BF ? !newChar.getDataFlipX() : newChar.getDataFlipX();
        newChar.alpha = parent.charAlpha.pos;
        newChar.angle = parent.charAngle.pos;
        newChar.scrollFactor.x = parent.charScrollX.pos;
        newChar.scrollFactor.y = parent.charScrollY.pos;

        state.selectedChar = newChar;
        group.add(newChar);

        parent.repositionCharacter();
        group.zIndex = Std.int(parent.charZIdx.pos ?? 0);

        // Save the selection.
        switch (type)
        {
          case BF:
            Save.instance.stageBoyfriendChar = charId;
          case GF:
            Save.instance.stageGirlfriendChar = charId;
          case DAD:
            Save.instance.stageDadChar = charId;
          default:
            // Do nothing.
        }
      };

      charButton.onMouseOver = _ -> {
        charIconName.text = '${charData.name} [${charId}]';
      };
      charButton.onMouseOut = _ -> {
        charIconName.text = defaultText;
      };
      charGrid.addComponent(charButton);
    }

    charIconName.text = defaultText;

    this.alpha = 0;
    this.y -= 10;
    FlxTween.tween(this, {alpha: 1, y: this.y + 10}, 0.2, {ease: FlxEase.quartOut});
  }
}
