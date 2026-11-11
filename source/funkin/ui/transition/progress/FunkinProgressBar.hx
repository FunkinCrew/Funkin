package funkin.ui.transition.progress;

import flixel.util.FlxColor;
import funkin.assets.Assets.AssetType;
import funkin.assets.Paths;
import funkin.data.loading.LoadingCharacterData;
import funkin.graphics.FunkinSprite;
import funkin.group.FunkinGroup.FunkinSpriteGroup;
import funkin.modding.PolymodHandler;
import funkin.util.MathUtil;
import haxe.io.Path;
import json2object.JsonParser;
import polymod.Polymod;
import polymod.PolymodAssets;

/**
 * A FunkinGroup that holds a progress bar and a loading character on top.
 */
@:nullSafety
class FunkinProgressBar extends FunkinSpriteGroup
{
  /**
   * The default path for loading characters.
   */
  public static final CHARACTER_PATH:String = 'ui/loading/characters/';

  /**
   * The default paths for base game characters.
   */
  public static final BASE_GAME_CHARACTER_PATHS:Array<String> = [
    Paths.json('ui/loading/characters/bf/bf', false).toString(),
    Paths.json('ui/loading/characters/gf/gf', false).toString()
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

  /**
   * The loading bar.
   */
  var bar:FunkinSprite;

  /**
   * The mic stand sprite.
   */
  var micStand:FunkinSprite;

  public function new()
  {
    super();

    bar = new FunkinSprite();
    micStand = new FunkinSprite();
    character = new FunkinLoadingCharacter();

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

    // Assets for each character.
    for (entry in getCharacterEntries())
    {
      switch (type)
      {
        case IMAGE:
          results.push(Paths.image(entry.path, false));

        case XML:
          results.push(Paths.xml(entry.path, false));

        case JSON:
          results.push(Paths.json(entry.path, false));

        default:
          // No assets.
      }
    }

    // Additional shared assets.
    switch (type)
    {
      case IMAGE:
        results.push(funkin.assets.Paths.image('ui/loading/mic-stand'));

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

    micStand.loadTexture('ui/loading/mic-stand');
    micStand.scale.set(0.34, 0.34);
    micStand.updateHitbox();
    micStand.x = FlxG.width - (micStand.width + 45);
    micStand.y = FlxG.height - (micStand.height + 30);
    add(micStand);

    barTargetX = micStand.x;

    bar.alpha = 0.9;
    bar.makeSolidColor(Std.int(micStand.width) + BAR_PAD, Std.int(micStand.height) + BAR_PAD, FlxColor.BLACK);
    bar.setPosition(barTargetX, micStand.y);
    bar.zIndex = 200;
    add(bar);

    refresh();
    updateProgress(0, 10);
  }

  /**
   * Loads the loading screen character from the available list of characters.
   * This will randomly select a character based on their weights.
   *
   * NOTE: We need custom logic using PolymodAssets to load characters,
   * because this screen gets used during hot reloads when mods aren't enabled yet.
   */
  public function loadCharacter():Void
  {
    loadEntries((entries:Array<CharacterEntry>) ->
    {
      if (entries.length == 0) return;

      // Select a random character by weights.
      var entry:Null<CharacterEntry> = FlxG.random.getObject(entries, entries.map((entry) -> entry?.data?.weight));
      if (entry == null) return;

      // Load the character.
      var data:LoadingCharacterData = cast entry.data;
      character.loadCharacter(data, entry.path, entry.modId);
      character.zIndex = 300;
      add(character);
    });
  }

  /**
   * Update the visuals for the progress bar.
   * Call this when progress changes.
   *
   * @param loaded The number of items that have been loaded so far.
   * @param total The total number of items that need to be loaded.
   */
  public function updateProgress(loaded:Int, total:Int):Void
  {
    if (total <= 0) return;

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

  /**
   * Load character data so that
   */
  static function loadEntries(onComplete:Array<CharacterEntry>->Void):Void
  {
    var entries:Array<CharacterEntry> = getCharacterEntries();
    if (entries.length == 0)
    {
      onComplete([]);
      return;
    }

    var pending:Int = entries.length;
    var onEntryLoaded:(CharacterEntry, Null<String>) -> Void = (entry, jsonString) ->
    {
      entry.data = parseEntry(jsonString, '${entry.path}.json');

      pending--;
      if (pending == 0)
      {
        onComplete(entries.filter((entry) -> entry.data != null));
      }
    };

    for (entry in entries)
    {
      var assetPath:AssetPath = Paths.json(entry.path, false);
      #if html5
      var dataFuture = entry.modId != '' ? PolymodAssets.loadTextFromMod(assetPath.toString(), entry.modId) : funkin.assets.Assets.loadText(assetPath);
      dataFuture.onComplete((jsonString:String) ->
      {
        onEntryLoaded(entry, jsonString);
      }).onError((error:Dynamic) ->
        {
          trace(' LOADING SCREEN '.bold().bg_orange() + ' Could not load character data "${assetPath}": ${Std.string(error)}');
          onEntryLoaded(entry, null);
        });
      #else
      var jsonString:Null<String> = null;

      if (entry.modId == '')
      {
        @:privateAccess
        jsonString = Polymod.assetLibrary.getTextDirectly(assetPath.toString(), '');

        if (jsonString == null || jsonString == '')
        {
          if (assetPath.exists())
          {
            try
            {
              jsonString = funkin.assets.Assets.getText(assetPath);
            }
            catch (error:Dynamic)
            {
              trace(' LOADING SCREEN '.bold().bg_orange() + ' Could not read base character data "${assetPath}": ${Std.string(error)}');
            }
          }
        }
      }
      else
      {
        @:privateAccess
        jsonString = Polymod.assetLibrary.getTextDirectly(assetPath.toString(), entry.modId);
      }

      onEntryLoaded(entry, jsonString);
      #end
    }
  }

  static function getCharacterEntries():Array<CharacterEntry>
  {
    var entries:Array<CharacterEntry> = [];

    // Load base game characters.
    for (path in BASE_GAME_CHARACTER_PATHS)
    {
      entries.push({
        path: Path.withoutExtension(normalizeAssetPath(path)),
        data: null,
        modId: ''
      });
    }

    // Load modded characters.
    for (modId in PolymodHandler.loadedModIds)
    {
      if (modId == null || modId == '' || modId == 'basegame') continue;

      var paths:Array<String> = PolymodAssets.listInMod(modId);
      var filteredPaths:Array<String> = paths.filter((assetPath) ->
      {
        var path:String = normalizeAssetPath(assetPath);
        return path.startsWith(CHARACTER_PATH) && path.endsWith('.json');
      });

      for (assetPath in filteredPaths)
      {
        var path:String = normalizeAssetPath(assetPath);
        var entryPath:String = Path.withoutExtension(path);
        var existing:Null<CharacterEntry> = entries.find((entry) -> entry.path == entryPath);

        if (existing != null)
        {
          existing.modId = modId;
        }
        else
        {
          entries.push({
            path: entryPath,
            data: null,
            modId: modId
          });
        }
      }
    }

    return entries;
  }

  /**
   * Normalize asset path to a path relative to the assets folder.
   */
  static function normalizeAssetPath(path:String):String
  {
    var normalized:String = StringTools.replace(path, '\\', '/');

    while (normalized.startsWith('/'))
    {
      normalized = normalized.substr(1);
    }

    if (normalized.startsWith('assets/'))
    {
      normalized = normalized.substr('assets/'.length);
    }

    return normalized;
  }

  static function parseEntry(jsonString:Null<String>, path:String):Null<LoadingCharacterData>
  {
    if (jsonString == null || jsonString == '') return null;

    var parser:JsonParser<LoadingCharacterData> = new JsonParser<LoadingCharacterData>({
      ignoreUnknownVariables: false
    });
    parser.fromJson(jsonString, path);

    if (parser.errors.length > 0)
    {
      trace(' LOADING SCREEN '.bold().bg_orange() + ' Failed to parse character data! (asset path: $path)');
      for (error in parser.errors) funkin.data.DataError.printError(error);
      return null;
    }

    return parser.value;
  }
}

/**
 * The data for a single loading screen character, along with its ID, path, and the mod it's from.
 */
typedef CharacterEntry =
{
  var path:String;
  var data:Null<LoadingCharacterData>;
  var modId:String;
}
