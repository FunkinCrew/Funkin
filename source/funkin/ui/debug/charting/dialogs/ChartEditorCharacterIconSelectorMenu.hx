package funkin.ui.debug.charting.dialogs;

#if FEATURE_CHART_EDITOR
import flixel.math.FlxPoint;
import funkin.data.character.CharacterData;
import funkin.data.character.CharacterRegistry;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.components.HealthIcon;
import funkin.util.SortUtil;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.containers.Grid;
import haxe.ui.containers.ScrollView;
import haxe.ui.core.Screen;
import haxe.ui.events.UIEvent;

private typedef CharacterEntry = {
  var id:String;
  var name:String;
  var button:Button;
  var isNone:Bool;
};

// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/ui/editors/chart-editor/dialogs/character-icon-selector.xml"))
class ChartEditorCharacterIconSelectorMenu extends ChartEditorBaseMenu
{
  public var charSelectScroll:ScrollView;
  public var charIconName:Label;
  public var charSearch:TextField;

  var charEntries:Array<CharacterEntry> = [];
  var currentCharButton:Null<Button> = null;
  var currentCharId:String = '';
  var defaultText:String = '(choose a character)';
  var initialScrollPos:Float = 0;

  public function new(chartEditorState2:ChartEditorState,
    charType:CharacterType,
    lockPosition:Bool = false)
  {
    super(chartEditorState2);

    initialize(charType, lockPosition);
  }

  function initialize(charType:CharacterType, lockPosition:Bool)
  {
    currentCharId = switch (charType)
    {
      case BF:
        chartEditorState.currentSongMetadata.playData.characters.player;
      case GF:
        chartEditorState.currentSongMetadata.playData.characters.girlfriend;
      case DAD:
        chartEditorState.currentSongMetadata.playData.characters.opponent;
      default:
        throw 'Invalid charType: ' + charType;
    };

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

    var charGrid = new Grid();
    charGrid.columns = 5;
    charGrid.width = this.width;
    charSelectScroll.addComponent(charGrid);

    var charIds:Array<String> = CharacterRegistry.instance.listEntryIds();
    charIds.sort(SortUtil.alphabetically);

    charIds.insert(0, ''); // Add None option.

    for (charIndex => charId in charIds)
    {
      var charData:CharacterData = CharacterRegistry.instance.fetchCharacterData(charId);
      var charName:String = (charId != '') ? charData.name : 'None';
      var charLabel:String = (charId != '') ? '${charName} [${charId}]' : 'None';

      var charButton = new Button();
      charButton.width = 70;
      charButton.height = 70;
      charButton.padding = 8;
      charButton.iconPosition = "top";

      if (charId == currentCharId)
      {
        initialScrollPos = Math.floor(charIndex / 5) * 80;
        charSelectScroll.vscrollPos = initialScrollPos;

        defaultText = charLabel;

        currentCharButton = charButton;
      }

      var LIMIT = 6;
      var pixelIcon = CharacterRegistry.getCharPixelIconAsset(charId);
      charButton.icon = pixelIcon != null ? haxe.ui.util.Variant.fromImageData(pixelIcon) : null;
      charButton.text = (charName.length > LIMIT) ? '${charName.substr(0, LIMIT)}.' : charName;

      charButton.onClick = _ ->
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

        defaultText = charLabel;
        chartEditorState.healthIconsDirty = true;

        chartEditorState.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
      };

      charButton.onMouseOver = _ ->
      {
        charIconName.text = charLabel;
      };
      charButton.onMouseOut = _ ->
      {
        charIconName.text = defaultText;
      };

      charEntries.push({
        id: charId,
        name: charName,
        button: charButton,
        isNone: charId == ''
      });

      charGrid.addComponent(charButton);
    }

    charIconName.text = defaultText;
    charSearch.onChange = onSearchChanged;
  }

  function focusCurrentCharacter():Void
  {
    if (currentCharButton == null) return;

    if ((charSearch.text ?? '').length == 0) charSelectScroll.vscrollPos = initialScrollPos;
    currentCharButton.focus = true;
  }

  function onSearchChanged(_:UIEvent):Void
  {
    var term:String = StringTools.trim(charSearch.text ?? '').toLowerCase();

    var matchCount:Int = 0;

    for (entry in charEntries)
    {
      if (entry.isNone)
      {
        entry.button.hidden = false;
        continue;
      }

      var matches:Bool = term.length == 0
        || entry.name.toLowerCase().indexOf(term) != -1
        || entry.id.toLowerCase().indexOf(term) != -1;

      entry.button.hidden = !matches;

      if (matches) matchCount++;
    }

    charIconName.text = (term.length > 0 && matchCount == 0) ? 'No characters found' : defaultText;

    charSelectScroll.vscrollPos = 0;
    charSelectScroll.hscrollPos = 0;
  }

  public static function build(chartEditorState:ChartEditorState,
    charType:CharacterType,
    lockPosition:Bool = false):ChartEditorCharacterIconSelectorMenu
  {
    var menu = new ChartEditorCharacterIconSelectorMenu(chartEditorState, charType, lockPosition);

    Screen.instance.addComponent(menu);
    haxe.ui.Toolkit.callLater(() -> menu.focusCurrentCharacter());

    return menu;
  }
}
#end
