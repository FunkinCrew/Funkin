package funkin.ui.debug.charting.dialogs;

import flixel.math.FlxPoint;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.character.CharacterData;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.components.HealthIcon;
import funkin.util.SortUtil;
import haxe.ui.components.Label;
import haxe.ui.containers.Grid;
import haxe.ui.containers.ScrollView;
import haxe.ui.core.Screen;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import haxe.ui.components.Button;

// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/dialogs/character-icon-selector.xml"))
class ChartEditorCharacterIconSelectorMenu extends ChartEditorBaseMenu
{
  public var charSelectScroll:ScrollView;
  public var charIconName:Label;

  var currentCharButton:Null<Button> = null;
  var currentCharId:String = '';

  public function new(chartEditorState2:ChartEditorState, charType:CharacterType, lockPosition:Bool = false)
  {
    super(chartEditorState2);

    initialize(charType, lockPosition);
    this.alpha = 0;
    this.y -= 10;
    FlxTween.tween(this, {alpha: 1, y: this.y + 10}, 0.2,
      {
        ease: FlxEase.quartOut,
        onComplete: function(_) {
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

    // Position this menu.
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

      var charButton = new Button();
      charButton.width = 70;
      charButton.height = 70;
      charButton.padding = 8;
      charButton.iconPosition = "top";

      if (charId == currentCharId)
      {
        // Scroll to the character if it is already selected.
        charSelectScroll.vscrollPos = Math.floor(charIndex / 5) * 80;
        charButton.focus = true;

        defaultText = (currentCharId != "") ? '${charData.name} [${charId}]' : 'None';

        currentCharButton = charButton;
      }

      var LIMIT = 6;
      charButton.icon = haxe.ui.util.Variant.fromImageData(CharacterDataParser.getCharPixelIconAsset(charId));
      charButton.text = (charId != "") ? (charData.name.length > LIMIT ? '${charData.name.substr(0, LIMIT)}.' : '${charData.name}') : 'None';

      charButton.onClick = _ -> {
        switch (charType)
        {
          case BF: chartEditorState.currentSongMetadata.playData.characters.player = charId;
          case GF: chartEditorState.currentSongMetadata.playData.characters.girlfriend = charId;
          case DAD: chartEditorState.currentSongMetadata.playData.characters.opponent = charId;
          default: throw 'Invalid charType: ' + charType;
        };

        defaultText = (charId != "") ? '${charData.name} [${charId}]' : 'None';
        chartEditorState.healthIconsDirty = true;
        chartEditorState.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
      };

      charButton.onMouseOver = _ -> {
        charIconName.text = (charId != "") ? '${charData.name} [${charId}]' : 'None';
      };
      charButton.onMouseOut = _ -> {
        charIconName.text = defaultText;
      };
      charGrid.addComponent(charButton);
    }

    charIconName.text = defaultText;
  }

  public static function build(chartEditorState:ChartEditorState, charType:CharacterType, lockPosition:Bool = false):ChartEditorCharacterIconSelectorMenu
  {
    var menu = new ChartEditorCharacterIconSelectorMenu(chartEditorState, charType, lockPosition);

    Screen.instance.addComponent(menu);

    return menu;
  }
}
