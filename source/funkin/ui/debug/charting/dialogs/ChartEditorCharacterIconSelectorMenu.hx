package funkin.ui.debug.charting.dialogs;

#if FEATURE_CHART_EDITOR
import flixel.math.FlxPoint;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.data.character.CharacterData;
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.play.components.HealthIcon;
import funkin.util.SortUtil;
import haxe.ui.components.Label;
import haxe.ui.containers.Grid;
import haxe.ui.containers.ScrollView;
import haxe.ui.core.Screen;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.data.DataSource;

// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/dialogs/character-icon-selector.xml"))
class ChartEditorCharacterIconSelectorMenu extends ChartEditorBaseMenu
{
  public var charSelectScroll:ScrollView;
  public var charIconName:Label;
  public var charVariationDropdown:DropDown;

  var currentCharButton:Null<Button> = null;
  var currentCharId:String = '';
  var currentBaseCharId:String = '';
  var charType:CharacterType;

  var lastSelectedVariations:Map<String, String> = new Map();

  function findBaseCharacterId(charId:String):String
  {
    if (charId == "") return "";

    var charIds:Array<String> = CharacterDataParser.listCharacterIds();

    for (baseId in charIds)
    {
      var charData:CharacterData = CharacterDataParser.fetchCharacterData(baseId);

      if (charData?.isVariation) continue;

      if (baseId == charId) return charId;

      if (charData != null && charData.variations != null && charData.variations.variations != null)
      {
        var variations = charData.variations.variations;
        var keys = variations.keys();

        for (vName in keys)
        {
          if (variations.get(vName) == charId)
          {
            return baseId;
          }
        }
      }
    }

    return charId;
  }

  function getCurrentVariationForBase(baseId:String):String
  {
    if (baseId == "") return "";

    if (lastSelectedVariations.exists(baseId)) return lastSelectedVariations.get(baseId);

    return baseId;
  }

  function saveVariationForBase(baseId:String, variationId:String):Void
  {
    if (baseId != "" && variationId != "") lastSelectedVariations.set(baseId, variationId);
  }

  function buildVariationItems(baseId:String, baseData:CharacterData):Array<Dynamic>
  {
    var items:Array<Dynamic> = [];

    if (baseId == "" || baseData == null)
    {
      items.push({id: "", text: "None"});
      return items;
    }

    items.push({id: baseId, text: "Default"});

    if (baseData.variations != null && baseData.variations.variations != null)
    {
      var variations = baseData.variations.variations;
      var keys = variations.keys();

      for (vName in keys)
      {
        var vId = variations.get(vName);
        items.push({id: vId, text: vName});
      }
    }

    return items;
  }

  function populateVariationDropdown(baseId:String, baseData:CharacterData, selectedId:String):Void
  {
    charVariationDropdown.dataSource.clear();

    if (baseId == "" || baseData == null)
    {
      charVariationDropdown.dataSource.add({id: "", text: "None"});
      charVariationDropdown.selectedItem = {id: "", text: "None"};
      charVariationDropdown.disabled = true;
      return;
    }

    charVariationDropdown.disabled = false;
    var items = buildVariationItems(baseId, baseData);

    for (item in items)
    {
      charVariationDropdown.dataSource.add(item);
    }

    var foundItem = null;
    for (item in items)
    {
      if (item.id == selectedId)
      {
        foundItem = item;
        break;
      }
    }

    if (foundItem != null)
    {
      charVariationDropdown.selectedItem = foundItem;
    }
    else if (items.length > 0)
    {
      charVariationDropdown.selectedItem = items[0];
    }
  }

  public function new(chartEditorState2:ChartEditorState, charType:CharacterType, lockPosition:Bool = false)
  {
    super(chartEditorState2);
    this.charType = charType;
    initialize(charType, lockPosition);
    this.alpha = 0;
    this.y -= 10;
    FlxTween.tween(this, {alpha: 1, y: this.y + 10}, 0.2, {
      ease: FlxEase.quartOut,
      onComplete: function(_)
      {
        // Just focus the button FFS. Idk why, but the scrollbar doesn't update until after the tween finishes with this????
        if (currentCharButton != null) currentCharButton.focus = true;
        else
          chartEditorState.error('Failure', 'Could not find character of ${currentCharId} in registry (Is the character in the registry?)');
      }
    });
  }

  function initialize(charType:CharacterType, lockPosition:Bool)
  {
    currentCharId = switch (charType)
    {
      case BF: chartEditorState.currentSongMetadata.playData.characters.player;
      case GF: chartEditorState.currentSongMetadata.playData.characters.girlfriend;
      case DAD: chartEditorState.currentSongMetadata.playData.characters.opponent;
      default: throw 'Invalid charType: ' + charType;
    };

    currentBaseCharId = findBaseCharacterId(currentCharId);

    if (currentBaseCharId != "") lastSelectedVariations.set(currentBaseCharId, currentCharId);

    var targetHealthIcon:Null<HealthIcon> = switch (charType)
    {
      case BF: chartEditorState.healthIconBF;
      case DAD: chartEditorState.healthIconDad;
      default: null;
    };

    if (lockPosition && targetHealthIcon != null)
    {
      var healthIconBottomCenter:FlxPoint = new FlxPoint(targetHealthIcon.x + targetHealthIcon.width / 2, targetHealthIcon.y + targetHealthIcon.height);

      this.x = healthIconBottomCenter.x - this.width / 2;
      this.y = healthIconBottomCenter.y;
    }
    else
    {
      this.x = Screen.instance.currentMouseX;
      this.y = Screen.instance.currentMouseY;
    }

    var charGrid = new Grid();
    charGrid.columns = 5;
    charGrid.width = this.width;
    charSelectScroll.addComponent(charGrid);

    var charIds:Array<String> = CharacterDataParser.listCharacterIds();
    charIds.sort(SortUtil.alphabetically);

    charIds.insert(0, ""); // Add none/null/NuN character option

    var defaultText:String = '(choose a character)';

    for (charIndex => charId in charIds)
    {
      var charData:CharacterData = CharacterDataParser.fetchCharacterData(charId);

      if (charData?.isVariation) continue;

      var charButton = new Button();
      charButton.width = 70;
      charButton.height = 70;
      charButton.padding = 8;
      charButton.iconPosition = "top";

      var isCurrentChar = (charId == currentBaseCharId);

      if (isCurrentChar)
      {
        // Scroll to the character if it is already selected.
        charSelectScroll.vscrollPos = Math.floor(charIndex / 5) * 80;
        charButton.focus = true;

        // Get the actual character data for display (could be variation)
        var displayCharData:CharacterData = CharacterDataParser.fetchCharacterData(currentCharId);
        defaultText = (currentCharId != "") ? '${displayCharData.name} [${currentCharId}]' : 'None';

        currentCharButton = charButton;

        populateVariationDropdown(charId, charData, currentCharId);
      }

      var LIMIT = 6;
      charButton.icon = haxe.ui.util.Variant.fromImageData(CharacterDataParser.getCharPixelIconAsset(charId));
      charButton.text = (charId != "") ? (charData.name.length > LIMIT ? '${charData.name.substr(0, LIMIT)}.' : '${charData.name}') : 'None';

      charButton.onClick = _ -> {
        var savedVariationId = getCurrentVariationForBase(charId);
        currentBaseCharId = charId;
        currentCharId = savedVariationId;

        var baseCharData = CharacterDataParser.fetchCharacterData(charId);

        populateVariationDropdown(charId, baseCharData, currentCharId);

        applyCharacter(currentCharId);

        // Get the actual character data for display (could be variation)
        var displayCharData:CharacterData = CharacterDataParser.fetchCharacterData(currentCharId);
        defaultText = (currentCharId != "") ? '${displayCharData.name} [${currentCharId}]' : 'None';
        charIconName.text = defaultText;
      };

      charButton.onMouseOver = _ -> {
        var hoverCharData = CharacterDataParser.fetchCharacterData(charId);
        charIconName.text = (charId != "") ? '${hoverCharData.name} [${charId}]' : 'None';
      };
      charButton.onMouseOut = _ -> {
        // Get the actual character data for display (could be variation)
        var currentCharData:CharacterData = CharacterDataParser.fetchCharacterData(currentCharId);
        if (currentCharData != null)
        {
          charIconName.text = (currentCharId != "") ? '${currentCharData.name} [${currentCharId}]' : 'None';
        }
        else
        {
          charIconName.text = defaultText;
        }
      };
      charGrid.addComponent(charButton);
    }


    // todo: fix rebase
    charVariationDropdown.onChange = function(_) {
      var selectedItem = charVariationDropdown.selectedItem;
      if (selectedItem != null)
      {
        var selectedId:String = selectedItem.id;
        currentCharId = selectedId;

        saveVariationForBase(currentBaseCharId, selectedId);

        applyCharacter(selectedId);

        // Get the actual character data for display (could be variation)
        var selectedCharData:CharacterData = CharacterDataParser.fetchCharacterData(selectedId);
        var displayName = "";

        if (selectedId == currentBaseCharId)
        {
          // For default variation, use base character name
          displayName = selectedCharData != null ? selectedCharData.name : selectedId;
        }
        else if (selectedId == "")
        {
          displayName = "None";
        }
        else
        {
          // For variation, use the variation's own name
          displayName = selectedCharData != null ? selectedCharData.name : selectedId;
        }

        charIconName.text = (selectedId != "") ? '${displayName} [${selectedId}]' : 'None';
      }
    };

    // Set initial text using current character data (could be variation)
    var initialCharData:CharacterData = CharacterDataParser.fetchCharacterData(currentCharId);
    charIconName.text = (currentCharId != "") ? '${initialCharData.name} [${currentCharId}]' : 'None';
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
        throw 'Invalid charType: ' + charType;
    };

    chartEditorState.healthIconsDirty = true;
    chartEditorState.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
  }

  public static function build(chartEditorState:ChartEditorState, charType:CharacterType, lockPosition:Bool = false):ChartEditorCharacterIconSelectorMenu
  {
    var menu = new ChartEditorCharacterIconSelectorMenu(chartEditorState, charType, lockPosition);

    Screen.instance.addComponent(menu);

    return menu;
  }
}
#end
