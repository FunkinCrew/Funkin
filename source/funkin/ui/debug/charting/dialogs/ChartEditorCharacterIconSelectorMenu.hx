package funkin.ui.debug.charting.dialogs;

#if FEATURE_CHART_EDITOR
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.data.character.CharacterData;
import funkin.data.character.CharacterRegistry;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.components.HealthIcon;
import funkin.util.SortUtil;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.containers.Grid;
import haxe.ui.containers.ScrollView;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;

// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/chart-editor/dialogs/character-icon-selector.xml'))
class ChartEditorCharacterIconSelectorMenu extends ChartEditorBaseMenu
{
  public var charSelectScroll:ScrollView;
  public var charIconName:Label;
  public var charVariationDropdown:DropDown;

  var currentCharButton:Null<Button> = null;
  var currentCharId:String = '';
  var currentBaseCharId:String = '';
  var charType:CharacterType;
  var fadeTween:FlxTween;
  var isUpdatingVariationDropdown:Bool = false;

  /**
   * Remembers the last picked variation for each base character while this
   * selector is open.
   */
  final lastSelectedVariations:Map<String, String> = new Map<String, String>();

  public function new(chartEditorState2:ChartEditorState,
    charType:CharacterType,
    lockPosition:Bool = false)
  {
    super(chartEditorState2);

    this.charType = charType;

    initialize(charType, lockPosition);

    this.alpha = 0;
    this.y -= 10;
    fadeTween = FlxTween.tween(this, {
      alpha: 1,
      y: this.y + 10
    }, 0.2, {
      ease: FlxEase.quartOut,
      onComplete: function(_)
      {
        // Just focus the button FFS. Idk why, but the scrollbar doesn't update until after the tween finishes with this????
        if (currentCharButton != null)
        {
          currentCharButton.focus = true;
        }
        else if (currentCharId != '')
        {
          chartEditorState.error('Failure', 'Could not find character "${currentCharId}" in the character registry.');
        }
      }
    });
  }

  function initialize(charType:CharacterType, lockPosition:Bool):Void
  {
    currentCharId = getSongCharacterId(charType);
    currentBaseCharId = currentCharId == '' ? '' : (CharacterRegistry.instance.getBaseCharacterId(currentCharId) ?? currentCharId);

    if (currentBaseCharId != '' && currentCharId != '')
    {
      lastSelectedVariations.set(currentBaseCharId, currentCharId);
    }

    positionMenu(charType, lockPosition);
    buildCharacterGrid();
    buildVariationDropdown();

    charIconName.text = getCharacterDisplayText(currentCharId);
  }

  function getSongCharacterId(charType:CharacterType):String
  {
    return switch (charType)
    {
      case BF:
        chartEditorState.currentSongMetadata.playData.characters.player;
      case GF:
        chartEditorState.currentSongMetadata.playData.characters.girlfriend;
      case DAD:
        chartEditorState.currentSongMetadata.playData.characters.opponent;
      default:
        throw 'Invalid character type: ' + charType;
    };
  }

  function positionMenu(charType:CharacterType, lockPosition:Bool):Void
  {
    var targetHealthIcon:Null<HealthIcon> = switch (charType)
    {
      case BF:
        chartEditorState.healthIconBF;
      case DAD:
        chartEditorState.healthIconDad;
      default:
        null;
    };

    if (lockPosition && targetHealthIcon != null)
    {
      var healthIconBottomCenter:FlxPoint = FlxPoint.weak(targetHealthIcon.x + targetHealthIcon.width / 2, targetHealthIcon.y + targetHealthIcon.height);

      this.x = healthIconBottomCenter.x - this.width / 2;
      this.y = healthIconBottomCenter.y;
    }
    else
    {
      this.x = Screen.instance.currentMouseX;
      this.y = Screen.instance.currentMouseY;
    }
  }

  function buildCharacterGrid():Void
  {
    var charGrid = new Grid();
    charGrid.columns = 5;
    charGrid.width = charSelectScroll.width;
    charSelectScroll.addComponent(charGrid);

    var characterIds:Array<String> = CharacterRegistry.instance.listBaseCharacterIds();
    characterIds.sort(SortUtil.alphabetically);
    characterIds.insert(0, ''); // Empty ID represents None.

    for (charIndex => charId in characterIds)
    {
      var charData:Null<CharacterData> = charId == '' ? null : CharacterRegistry.instance.fetchCharacterData(charId);
      if (charId != '' && charData == null) continue;

      var charButton = new Button();
      charButton.width = 70;
      charButton.height = 70;
      charButton.padding = 8;
      charButton.iconPosition = 'top';

      if (charId == currentBaseCharId)
      {
        // Scroll to the selected base character when the menu opens.
        charSelectScroll.vscrollPos = Math.floor(charIndex / charGrid.columns) * 80;
        currentCharButton = charButton;
      }

      var pixelIcon = charId == '' ? null : CharacterRegistry.getCharPixelIconAsset(charId);
      charButton.icon = pixelIcon != null ? haxe.ui.util.Variant.fromImageData(pixelIcon) : null;
      charButton.text = charId == '' ? 'None' : shortenCharacterName(charData.name);

      charButton.onClick = _ -> selectBaseCharacter(charId);
      charButton.onMouseOver = _ -> charIconName.text = getCharacterDisplayText(getPreviewCharacterId(charId));
      charButton.onMouseOut = _ -> charIconName.text = getCharacterDisplayText(currentCharId);

      charGrid.addComponent(charButton);
    }
  }

  function buildVariationDropdown():Void
  {
    charVariationDropdown.onChange = function(_)
    {
      if (isUpdatingVariationDropdown) return;

      if (charVariationDropdown.selectedItem == null) return;

      var selectedId:String = charVariationDropdown.selectedItem.id;
      if (selectedId == currentCharId) return;

      currentCharId = selectedId;
      if (currentBaseCharId != '')
      {
        lastSelectedVariations.set(currentBaseCharId, currentCharId);
      }

      applyCharacter(currentCharId);
      charIconName.text = getCharacterDisplayText(currentCharId);
    };

    populateVariationDropdown(currentBaseCharId, currentCharId);
  }

  function populateVariationDropdown(baseId:String, selectedId:String):Void
  {
    isUpdatingVariationDropdown = true;
    charVariationDropdown.dataSource.clear();

    if (baseId == '')
    {
      var noneItem = {
        id: '',
        text: 'None'
      };
      charVariationDropdown.dataSource.add(noneItem);
      charVariationDropdown.selectedItem = noneItem;
      charVariationDropdown.disabled = true;
      isUpdatingVariationDropdown = false;
      return;
    }

    var variations = CharacterRegistry.instance.getCharacterVariations(baseId);
    var selectedItem:Null<Dynamic> = null;

    for (variation in variations)
    {
      var item = {
        id: variation.id,
        text: variation.name
      };
      charVariationDropdown.dataSource.add(item);

      if (variation.id == selectedId)
      {
        selectedItem = item;
      }
    }

    if (selectedItem == null && variations.length > 0)
    {
      selectedItem = {
        id: variations[0].id,
        text: variations[0].name
      };
    }

    charVariationDropdown.disabled = variations.length <= 1;
    if (selectedItem != null)
    {
      charVariationDropdown.selectedItem = selectedItem;
    }

    isUpdatingVariationDropdown = false;
  }

  function selectBaseCharacter(baseId:String):Void
  {
    currentBaseCharId = baseId;

    if (baseId == '')
    {
      currentCharId = '';
      populateVariationDropdown('', '');
      applyCharacter('');
      charIconName.text = getCharacterDisplayText('');
      return;
    }

    var rememberedId:Null<String> = lastSelectedVariations.get(baseId);
    currentCharId = baseId;
    if (rememberedId != null && isVariationAvailable(baseId, rememberedId))
    {
      currentCharId = rememberedId;
    }

    populateVariationDropdown(baseId, currentCharId);
    applyCharacter(currentCharId);
    charIconName.text = getCharacterDisplayText(currentCharId);
  }

  function isVariationAvailable(baseId:String, variationId:Null<String>):Bool
  {
    if (variationId == null || variationId == '') return false;

    for (variation in CharacterRegistry.instance.getCharacterVariations(baseId))
    {
      if (variation.id == variationId) return true;
    }

    return false;
  }

  function getPreviewCharacterId(baseId:String):String
  {
    if (baseId == '') return '';

    var rememberedId:Null<String> = lastSelectedVariations.get(baseId);
    if (rememberedId != null && isVariationAvailable(baseId, rememberedId))
    {
      return rememberedId;
    }

    return baseId;
  }

  function getCharacterDisplayText(charId:String):String
  {
    if (charId == '') return 'None';

    var charData:Null<CharacterData> = CharacterRegistry.instance.fetchCharacterData(charId);
    var displayName:String = charData != null ? charData.name : charId;
    return '${displayName} [${charId}]';
  }

  function shortenCharacterName(name:String, maxLength:Int = 7):String
  {
    if (name.length <= maxLength) return name;
    return '${name.substr(0, maxLength - 1)}…';
  }

  function applyCharacter(charId:String):Void
  {
    switch (charType)
    {
      case BF:
        chartEditorState.currentSongMetadata.playData.characters.player = charId;
        chartEditorState.playerPreviewDirty = true;
      case GF:
        chartEditorState.currentSongMetadata.playData.characters.girlfriend = charId;
      case DAD:
        chartEditorState.currentSongMetadata.playData.characters.opponent = charId;
        chartEditorState.opponentPreviewDirty = true;
      default:
        throw 'Invalid character type: ' + charType;
    };

    chartEditorState.healthIconsDirty = true;
    chartEditorState.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
  }

  override function onDestroy():Void
  {
    fadeTween.cancel();
    super.onDestroy();
  }

  public static function build(chartEditorState:ChartEditorState,
    charType:CharacterType,
    lockPosition:Bool = false):ChartEditorCharacterIconSelectorMenu
  {
    var menu = new ChartEditorCharacterIconSelectorMenu(chartEditorState, charType, lockPosition);

    Screen.instance.addComponent(menu);

    return menu;
  }
}
#end
