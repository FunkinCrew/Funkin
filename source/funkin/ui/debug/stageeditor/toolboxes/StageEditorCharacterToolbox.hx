package funkin.ui.debug.stageeditor.toolboxes;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.play.character.BaseCharacter;
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.data.character.CharacterData;
import funkin.data.stage.StageData.StageDataCharacter;
import funkin.util.SortUtil;
import funkin.save.Save;
import haxe.ui.core.Screen;
import haxe.ui.components.Button;
import haxe.ui.components.NumberStepper;
import haxe.ui.containers.Grid;
import haxe.ui.containers.menus.Menu;
import haxe.ui.events.UIEvent;

// @:nullSafety

@:access(funkin.ui.debug.stageeditor.StageEditorState)
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/toolboxes/character-properties.xml"))
class StageEditorCharacterToolbox extends StageEditorBaseToolbox
{
  var linkedCharacter:Null<BaseCharacter> = null;

  var inputCharacterPositionX:NumberStepper;
  var inputCharacterPositionY:NumberStepper;
  var inputCharacterScale:NumberStepper;
  var inputCharacterZIndex:NumberStepper;
  var inputCharacterCameraOffsetX:NumberStepper;
  var inputCharacterCameraOffsetY:NumberStepper;
  var inputCharacterScrollX:NumberStepper;
  var inputCharacterScrollY:NumberStepper;
  var inputCharacterAlpha:NumberStepper;
  var inputCharacterAngle:NumberStepper;

  var buttonCharacterSelection:Button;
  var characterSelectionMenu:Menu;

  var dataCharacter:Null<StageDataCharacter> = null;

  public function new(stageEditorState2:StageEditorState)
  {
    super(stageEditorState2);

    initialize();

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    stageEditorState.menubarItemWindowCharacter.selected = false;
  }

  function initialize():Void
  {
    inputCharacterPositionX.onChange = inputCharacterPositionY.onChange = _ -> repositionCharacter();

    inputCharacterScale.onChange = _ -> repositionCharacter();

    inputCharacterZIndex.max = StageEditorState.MAX_Z_INDEX;
    inputCharacterZIndex.onChange = event -> {
      if (linkedCharacter == null) return;
      dataCharacter.zIndex = event.value;
      linkedCharacter.zIndex = event.value;
      stageEditorState.sortObjects();
    }

    inputCharacterCameraOffsetX.onChange = inputCharacterCameraOffsetY.onChange = _ -> {
      if (linkedCharacter == null) return;
      dataCharacter.cameraOffsets = [inputCharacterCameraOffsetX.pos, inputCharacterCameraOffsetY.pos];
      stageEditorState.updateVisuals();
    }

    inputCharacterScrollX.onChange = inputCharacterScrollY.onChange = _ -> {
      if (linkedCharacter == null) return;
      dataCharacter.scroll = [inputCharacterScrollX.pos, inputCharacterScrollY.pos];
      linkedCharacter.scrollFactor.set(inputCharacterScrollX.pos, inputCharacterScrollY.pos);
    }

    inputCharacterAlpha.onChange = event -> {
      if (linkedCharacter == null) return;
      dataCharacter.alpha = event.value;
      linkedCharacter.alpha = event.value;
    }

    inputCharacterAngle.onChange = event -> {
      if (linkedCharacter == null) return;
      dataCharacter.angle = event.value;
      linkedCharacter.angle = event.value;
    }

    buttonCharacterSelection.onClick = _ -> {
      if (linkedCharacter == null) return;
      characterSelectionMenu = new StageEditorCharacterMenu(stageEditorState, this);
      Screen.instance.addComponent(characterSelectionMenu);
    }
  }

  public override function refresh():Void
  {
    linkedCharacter = stageEditorState.selectedCharacter;

    inputCharacterPositionX.step = inputCharacterPositionY.step = stageEditorState.moveStep;
    inputCharacterAngle.step = stageEditorState.angleStep;

    // If there is no selected character, reset displays.
    if (linkedCharacter == null)
    {
      inputCharacterPositionX.pos = 0;
      inputCharacterPositionY.pos = 0;
      inputCharacterScale.pos = 1;
      inputCharacterZIndex.pos = 0;
      inputCharacterCameraOffsetX.pos = 0;
      inputCharacterCameraOffsetY.pos = 0;
      inputCharacterScrollX.pos = 1;
      inputCharacterScrollY.pos = 1;
      inputCharacterAlpha.pos = 1;
      inputCharacterAngle.pos = 0;

      buttonCharacterSelection.text = 'None';

      return;
    }

    dataCharacter = Reflect.field(stageEditorState.currentCharacters, Std.string(linkedCharacter.characterType).toLowerCase());

    // Otherwise, only update components whose linked character values have been changed.
    if (inputCharacterPositionX.pos != dataCharacter.position[0]) inputCharacterPositionX.pos = dataCharacter.position[0];
    if (inputCharacterPositionY.pos != dataCharacter.position[1]) inputCharacterPositionY.pos = dataCharacter.position[1];
    if (inputCharacterScale.pos != dataCharacter.scale / linkedCharacter.getBaseScale())
      inputCharacterScale.pos = dataCharacter.scale / linkedCharacter.getBaseScale();
    if (inputCharacterZIndex.pos != dataCharacter.zIndex) inputCharacterZIndex.pos = dataCharacter.zIndex;
    if (inputCharacterCameraOffsetX.pos != dataCharacter.cameraOffsets[0]) inputCharacterCameraOffsetX.pos = dataCharacter.cameraOffsets[0];
    if (inputCharacterCameraOffsetY.pos != dataCharacter.cameraOffsets[1]) inputCharacterCameraOffsetY.pos = dataCharacter.cameraOffsets[1];
    if (inputCharacterScrollX.pos != dataCharacter.scroll[0]) inputCharacterScrollX.pos = dataCharacter.scroll[0];
    if (inputCharacterScrollY.pos != dataCharacter.scroll[1]) inputCharacterScrollY.pos = dataCharacter.scroll[1];
    if (inputCharacterAlpha.pos != dataCharacter.alpha) inputCharacterAlpha.pos = dataCharacter.alpha;
    if (inputCharacterAngle.pos != dataCharacter.angle) inputCharacterAngle.pos = dataCharacter.angle;

    var prevText:String = buttonCharacterSelection.text;
    var characterData:Null<CharacterData> = CharacterDataParser.fetchCharacterData(linkedCharacter.characterId);
    buttonCharacterSelection.icon = (characterData == null ? null : haxe.ui.util.Variant.fromImageData(CharacterDataParser.getCharPixelIconAsset(linkedCharacter.characterId)));
    buttonCharacterSelection.text = (characterData == null ? "None" : characterData.name.length > 6 ? '${characterData.name.substr(0, 6)}.' : '${characterData.name}');

    if (prevText != buttonCharacterSelection.text) Screen.instance.removeComponent(characterSelectionMenu);
  }

  public function repositionCharacter()
  {
    if (linkedCharacter == null) return;

    linkedCharacter.x = inputCharacterPositionX.pos - linkedCharacter.characterOrigin.x + linkedCharacter.globalOffsets[0];
    linkedCharacter.y = inputCharacterPositionY.pos - linkedCharacter.characterOrigin.y + linkedCharacter.globalOffsets[1];
    dataCharacter.position = [
      linkedCharacter.feetPosition.x - linkedCharacter.globalOffsets[0],
      linkedCharacter.feetPosition.y - linkedCharacter.globalOffsets[1],
    ];

    linkedCharacter.setScale(linkedCharacter.getBaseScale() * inputCharacterScale.pos);
    dataCharacter.scale = inputCharacterScale.pos / linkedCharacter.getBaseScale();

    stageEditorState.updateVisuals();
  }

  public static function build(stageEditorState:StageEditorState):StageEditorCharacterToolbox
  {
    return new StageEditorCharacterToolbox(stageEditorState);
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
@:access(funkin.ui.debug.stageeditor.StageEditorState)
@:access(funkin.ui.debug.stageeditor.toolboxes.StageEditorCharacterToolbox)
class StageEditorCharacterMenu extends Menu
{
  override public function new(state:StageEditorState, parent:StageEditorCharacterToolbox)
  {
    super();

    this.x = Screen.instance.currentMouseX;
    this.y = Screen.instance.currentMouseY;

    var characterGrid = new Grid();
    characterGrid.columns = 5;
    characterGrid.width = this.width;
    charSelectScroll.addComponent(characterGrid);

    var charIds = CharacterDataParser.listCharacterIds();
    charIds.sort(SortUtil.alphabetically);

    var defaultText:String = '(choose a character)';

    for (charIndex => charId in charIds)
    {
      var charData:CharacterData = CharacterDataParser.fetchCharacterData(charId);

      var characterButton = new Button();
      characterButton.width = 70;
      characterButton.height = 70;
      characterButton.padding = 8;
      characterButton.iconPosition = "top";

      if (charId == parent.linkedCharacter.characterId)
      {
        // Scroll to the character if it is already selected.
        charSelectScroll.hscrollPos = Math.floor(charIndex / 5) * 80;
        characterButton.selected = true;

        defaultText = '${charData.name} [${charId}]';
      }

      var LIMIT = 6;
      characterButton.icon = haxe.ui.util.Variant.fromImageData(CharacterDataParser.getCharPixelIconAsset(charId));
      characterButton.text = charData.name.length > LIMIT ? '${charData.name.substr(0, LIMIT)}.' : '${charData.name}';

      characterButton.onClick = _ -> {
        var type = parent.linkedCharacter.characterType;
        if (parent.linkedCharacter.characterId == charId) return; // saves on memory

        state.remove(parent.linkedCharacter);
        state.characters.remove(Std.string(type).toLowerCase());

        var newCharacter = CharacterDataParser.fetchCharacter(charId, true);
        if (newCharacter == null)
        {
          state.error('Switch Character', "Couldn't find character " + charId + ". Switching to default.");
          newCharacter = CharacterDataParser.fetchCharacter(Constants.DEFAULT_CHARACTER, true);
        }

        newCharacter.characterType = type;

        newCharacter.resetCharacter(true);
        newCharacter.alpha = parent.inputCharacterAlpha.pos;
        newCharacter.angle = parent.inputCharacterAngle.pos;
        newCharacter.scrollFactor.x = parent.inputCharacterScrollX.pos;
        newCharacter.scrollFactor.y = parent.inputCharacterScrollY.pos;

        state.selectedCharacter = newCharacter;
        state.addCharacter(newCharacter, type);
        parent.repositionCharacter();
        newCharacter.zIndex = Std.int(parent.inputCharacterZIndex.pos ?? 0);

        // Save the selection.
        switch (type)
        {
          case BF: Save.instance.stageBoyfriendChar = charId;
          case GF: Save.instance.stageGirlfriendChar = charId;
          case DAD: Save.instance.stageDadChar = charId;
          default: // Do nothing.
        }
      };

      characterButton.onMouseOver = _ -> charIconName.text = '${charData.name} [${charId}]';
      characterButton.onMouseOut = _ -> charIconName.text = defaultText;
      characterGrid.addComponent(characterButton);
    }

    charIconName.text = defaultText;

    this.alpha = 0;
    this.y -= 10;
    FlxTween.tween(this, {alpha: 1, y: this.y + 10}, 0.2, {ease: FlxEase.quartOut});
  }
}
