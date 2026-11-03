package funkin.ui.transition.progress;

import flixel.util.FlxColor;
import funkin.assets.Assets.AssetType;
import funkin.assets.Paths;
import funkin.data.loading.LoadingCharacterData;
import funkin.graphics.FunkinSprite;
import funkin.group.FunkinGroup.FunkinSpriteGroup;
import funkin.modding.PolymodHandler;
import funkin.util.MathUtil;
import json2object.JsonParser;
import polymod.Polymod;
import polymod.PolymodAssets;

/**
 * A FunkinGroup that holds a progress bar and a a loading character on top.
 */
// @:nullSafety
class FunkinProgressBar extends FunkinSpriteGroup
{
  /**
   * The default path that a loading character is loaded from.
   */
  public static final CHARACTER_PATH:String = 'ui/loading/characters/';

  /**
   * The default paths for base game characters.
   */
  public static final BASE_GAME_CHARACTER_PATHS:Array<String> = [
    Paths.json('ui/loading/characters/bf/bf').toString(),
    Paths.json('ui/loading/characters/gf/gf').toString()
  ];

  /**
   * The extra padding around the progress bar.
   */
  public static final BAR_PAD:Int = 16;

  /**
   * The loading character instance.
   * This appears above the progress bar.
   */
  public var character:FunkinLoadingCharacter;

  /**
   * The target X position of the progress bar.
   */
  public var barTargetX:Float = 0;

  var dataList:Array<LoadingCharacterData> = [];
  var dataPaths:Array<String> = [];
  var dataModIds:Array<String> = [];
  var bar:FunkinSprite;
  var micStand:FunkinSprite;
  var barGraphicPaths:String;
  var barGraphicOffset:Array<Float>;
  var barScale:Float;
  var useAntialiasing:Bool;
  var useFlipX:Bool;

  public function new()
  {
    super();

    bar = new FunkinSprite();
    micStand = new FunkinSprite();
    character = new FunkinLoadingCharacter();

    barGraphicPaths = "ui/loading/mic-stand";
    barGraphicOffset = [0, 0];
    barScale = 0.34;

    useAntialiasing = true;
    useFlipX = false;

    customChildUpdate = true;
  }

  /**
   * Produce a list of all the AssetPaths that this interface depends on to load.
   * This is used to ensure those assets are properly cached during the preceding loading screen.
   *
   * @param type The type of AssetPath to return a list of paths for.
   * @return A list of AssetPaths of that type that the interface will use.
   */
  public static function queryAssets(type:AssetType):Array<AssetPath>
  {
    var results:Array<AssetPath> = [];

    switch (type)
    {
      case IMAGE:
        results.push(funkin.assets.Paths.image('ui/loading/mic-stand'));
        results.push(funkin.assets.Paths.image('ui/loading/characters/bf/bf'));
        results.push(funkin.assets.Paths.image('ui/loading/characters/gf/gf'));

      case XML:
        results.push(funkin.assets.Paths.xml('ui/loading/characters/bf/bf'));
        results.push(funkin.assets.Paths.xml('ui/loading/characters/gf/gf'));

      case JSON:
        results.push(funkin.assets.Paths.json('ui/loading/characters/bf/bf'));
        results.push(funkin.assets.Paths.json('ui/loading/characters/gf/gf'));

      default:
        // No assets.
    }

    return results;
  }

  /**
   * Create and display the progress bar visuals.
   * Call this only AFTER assets have been purged.
   */
  public function build():Void
  {
    trace('Building progress bar for display...');

    loadCharacter();

    micStand.loadTexture('${barGraphicPaths}');
    micStand.scale.set(barScale, barScale);
    micStand.updateHitbox();
    micStand.x = FlxG.width - (micStand.width + 45) + barGraphicOffset[0];
    micStand.y = FlxG.height - (micStand.height + 30) + barGraphicOffset[1];
    add(micStand);

    barTargetX = micStand.x;

    bar.alpha = 0.9;
    bar.makeSolidColor(Std.int(micStand.width) + BAR_PAD, Std.int(micStand.height) + BAR_PAD, FlxColor.BLACK);
    bar.setPosition(barTargetX, micStand.y);
    bar.zIndex = 200;
    add(bar);
    micStand.antialiasing = bar.antialiasing = useAntialiasing;
    bar.flipX = micStand.flipX = useFlipX;

    refresh();
    updateProgress(0, 10);
  }

  /**
   * Loads the loading screen character from the available list of characters.
   * This will randomly select a character based on their weights.
   */
  public function loadCharacter():Void
  {
    var enabledModIds:Array<String> = PolymodHandler.enabledModIds.copy();
    var dataFolderPaths:Array<String> = BASE_GAME_CHARACTER_PATHS.copy();
    // Parallel to dataFolderPaths. '' -> base game
    var dataFolderModIds:Array<String> = [for (_ in dataFolderPaths) ''];

    for (modId in enabledModIds)
    {
      if (modId == '') continue;

      // TODO: I know, I hate this too.
      var assets:Array<String> = PolymodAssets.listInMod(modId);

      for (asset in assets)
      {
        if (!asset.startsWith(CHARACTER_PATH) && !asset.endsWith('.json')) continue;
        dataFolderPaths.push(asset);
        dataFolderModIds.push(modId);
      }
    }

    dataList = [];
    dataPaths = [];
    dataModIds = [];
    loadDataFromPaths(dataFolderPaths, dataFolderModIds);

    if (dataList.length == 0) return;

    var weights:Array<Float> = [];
    for (data in dataList)
    {
      weights.push(data.weight);
    }

    var characterData:LoadingCharacterData = FlxG.random.getObject(dataList, weights);

    var idx:Int = dataList.indexOf(characterData);
    var characterId:String = dataPaths[idx].split('/').pop().split('.')[0];
    character.loadCharacter(characterData, '$CHARACTER_PATH$characterId/$characterId', dataModIds[idx]);
    character.zIndex = 300;
    add(character);

    // Check if the bar asset exist. if not, it loads the original one.
    if (Assets.exists('$CHARACTER_PATH$characterId/bar-$characterId.png'))
    {
      barGraphicPaths = '$CHARACTER_PATH$characterId/bar-$characterId';
    }

    useFlipX = characterData.barFlipX;

    barGraphicOffset = characterData.barOffsets;
    barScale = characterData.barScale;

    useAntialiasing = characterData.barAntialiasing;
  }

  /**
   * Loads the character data from the specified paths.
   * @param paths The paths to load character data from.
   * @param modIds The IDs of the mods that the character data belongs to.
   */
  public function loadDataFromPaths(paths:Array<String>, modIds:Array<String>):Void
  {
    for (i in 0...paths.length)
    {
      var path:String = paths[i];
      var modId:String = modIds[i];
      if (modId == 'basegame') modId = '';

      var jsonString:Null<String> = null;

      #if html5
      if (modId == '')
      {
        if (!lime.utils.Assets.isLocal(path, lime.utils.AssetType.TEXT)) continue;

        jsonString = lime.utils.Assets.getText(path);
      }
      else
      {
        jsonString = PolymodAssets.getTextFromMod(path, modId);
      }
      #else
      @:privateAccess
      jsonString = Polymod.assetLibrary.getTextDirectly(path, modId);
      #end

      if (jsonString == null || jsonString == '') continue;

      var parser:JsonParser<LoadingCharacterData> = new JsonParser<LoadingCharacterData>({
        ignoreUnknownVariables: false
      });
      parser.fromJson(jsonString, path);
      trace(parser.value);
      if (parser.errors.length > 0)
      {
        trace(' LOADING SCREEN '.bold().bg_orange() + ' Failed to parse character data! (asset path: $path)');
        for (error in parser.errors) funkin.data.DataError.printError(error);
      }
      else
      {
        dataList.push(parser.value);
        dataPaths.push(path);
        dataModIds.push(modId);
      }
    }
  }

  /**
   * Update the visuals for the progress bar.
   *
   * @param loaded The number of items that have been loaded so far.
   * @param total The total number of items that need to be loaded.
   */
  public function updateProgress(loaded:Int, total:Int):Void
  {
    var currentProgress:Float = (loaded / total).clamp(0, 1);
    barTargetX += (bar.width * currentProgress - BAR_PAD - BAR_PAD) + BAR_PAD;
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    for (child in children)
    {
      if (child != null && child.cameras != cameras) child.cameras = cameras;
    }

    bar.x = MathUtil.smoothLerpPrecision(bar.x, barTargetX, elapsed, 0.2);
  }
}
