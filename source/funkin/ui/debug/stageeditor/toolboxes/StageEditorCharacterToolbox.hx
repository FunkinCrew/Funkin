package funkin.ui.debug.stageeditor.toolboxes;

import haxe.ui.components.NumberStepper;
import funkin.play.character.BaseCharacter;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.util.SortUtil;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.components.DropDown;
import haxe.ui.components.Button;
import haxe.ui.components.Slider;
import haxe.ui.components.Label;
import funkin.ui.debug.stageeditor.handlers.StageDataHandler;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.ScrollView;
import haxe.ui.core.Screen;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import haxe.ui.containers.Grid;
import funkin.play.character.CharacterData;

using StringTools;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/toolboxes/character-properties.xml"))
class StageEditorCharacterToolbox extends StageEditorDefaultToolbox
{
  var characterPosXStepper:NumberStepper;
  var characterPosYStepper:NumberStepper;
  var characterPosReset:Button;

  var characterZIdxStepper:NumberStepper;
  var characterZIdxReset:Button;

  var characterCamXStepper:NumberStepper;
  var characterCamYStepper:NumberStepper;
  var characterCamReset:Button;

  var characterScaleSlider:Slider;
  var characterScaleReset:Button;

  var characterTypeButton:Button;
  var charMenu:StageEditorCharacterMenu;

  override public function new(state:StageEditorState)
  {
    super(state);

    // position
    characterPosXStepper.onChange = characterPosYStepper.onChange = function(_) {
      repositionCharacter();
      state.saved = false;
    }

    characterPosReset.onClick = function(_) {
      if (!StageEditorState.DEFAULT_POSITIONS.exists(state.selectedChar.characterType)) return;

      var oldPositions = StageEditorState.DEFAULT_POSITIONS[state.selectedChar.characterType];
      characterPosXStepper.pos = oldPositions[0];
      characterPosYStepper.pos = oldPositions[1];
    }

    // zidx
    characterZIdxStepper.max = StageEditorState.MAX_Z_INDEX;
    characterZIdxStepper.onChange = function(_) {
      state.charGroups[state.selectedChar.characterType].zIndex = Std.int(characterZIdxStepper.pos);
      state.saved = false;
      state.sortAssets();
    }

    characterZIdxReset.onClick = function(_) {
      var thingies = [CharacterType.GF, CharacterType.DAD, CharacterType.BF];
      var thingIdxies = thingies.indexOf(state.selectedChar.characterType);

      characterZIdxStepper.pos = (thingIdxies * 100);
    }

    // camera
    characterCamXStepper.onChange = characterCamYStepper.onChange = function(_) {
      state.charCamOffsets[state.selectedChar.characterType] = [characterCamXStepper.pos, characterCamYStepper.pos];
      state.updateMarkerPos();
      state.saved = false;
    }

    characterCamReset.onClick = function(_) characterCamXStepper.pos = characterCamYStepper.pos = 0; // lol

    // scale
    characterScaleSlider.onChange = function(_) {
      state.selectedChar.setScale(state.selectedChar.getBaseScale() * characterScaleSlider.pos);
      repositionCharacter();
      state.saved = false;
    }

    characterScaleReset.onChange = function(_) characterScaleSlider.pos = 1;

    // character button
    characterTypeButton.onClick = function(_) {
      charMenu = new StageEditorCharacterMenu(state, this);
      Screen.instance.addComponent(charMenu);
    }

    refresh();
  }

  override public function refresh()
  {
    var name = stageEditorState.selectedChar.characterType;

    characterPosXStepper.step = characterPosYStepper.step = stageEditorState.moveStep;
    characterCamXStepper.step = characterCamYStepper.step = stageEditorState.moveStep;

    if (characterPosXStepper.pos != stageEditorState.charPos[name][0]) characterPosXStepper.pos = stageEditorState.charPos[name][0];
    if (characterPosYStepper.pos != stageEditorState.charPos[name][1]) characterPosYStepper.pos = stageEditorState.charPos[name][1];

    if (characterZIdxStepper.pos != stageEditorState.charGroups[stageEditorState.selectedChar.characterType].zIndex)
      characterZIdxStepper.pos = stageEditorState.charGroups[stageEditorState.selectedChar.characterType].zIndex;

    if (characterCamXStepper.pos != stageEditorState.charCamOffsets[name][0]) characterCamXStepper.pos = stageEditorState.charCamOffsets[name][0];
    if (characterCamYStepper.pos != stageEditorState.charCamOffsets[name][1]) characterCamYStepper.pos = stageEditorState.charCamOffsets[name][1];

    if (characterScaleSlider.pos != stageEditorState.selectedChar.scale.x / stageEditorState.selectedChar.getBaseScale())
      characterScaleSlider.pos = stageEditorState.selectedChar.scale.x / stageEditorState.selectedChar.getBaseScale();

    var prevText = characterTypeButton.text;

    var charData = CharacterDataParser.fetchCharacterData(stageEditorState.selectedChar.characterId);
    characterTypeButton.icon = (charData == null ? null : CharacterDataParser.getCharPixelIconAsset(stageEditorState.selectedChar.characterId));
    characterTypeButton.text = (charData == null ? "None" : charData.name.length > 6 ? '${charData.name.substr(0, 6)}.' : '${charData.name}');

    if (prevText != characterTypeButton.text)
    {
      Screen.instance.removeComponent(charMenu);
    }
  }

  public function repositionCharacter()
  {
    stageEditorState.selectedChar.x = characterPosXStepper.pos - stageEditorState.selectedChar.characterOrigin.x
      + stageEditorState.selectedChar.globalOffsets[0];
    stageEditorState.selectedChar.y = characterPosYStepper.pos - stageEditorState.selectedChar.characterOrigin.y
      + stageEditorState.selectedChar.globalOffsets[1];

    stageEditorState.selectedChar.setScale(stageEditorState.selectedChar.getBaseScale() * characterScaleSlider.pos);

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

      var charButton = new haxe.ui.components.Button();
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
        newChar.characterType = type;

        newChar.resetCharacter(true);
        newChar.flipX = type == CharacterType.BF ? !newChar.getDataFlipX() : newChar.getDataFlipX();

        state.selectedChar = newChar;
        group.add(newChar);

        parent.repositionCharacter();
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
