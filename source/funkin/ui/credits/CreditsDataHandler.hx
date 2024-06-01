package funkin.ui.credits;

import funkin.data.JsonFile;

using StringTools;

@:nullSafety
class CreditsDataHandler
{
  public static final BACKER_PUBLIC_URL:String = 'https://funkin.me/backers';

  #if HARDCODED_CREDITS
  static final CREDITS_DATA_PATH:String = "assets/exclude/data/credits.json";
  #else
  static final CREDITS_DATA_PATH:String = "assets/data/credits.json";
  #end

  public static function debugPrint(data:Null<CreditsData>):Void
  {
    if (data == null)
    {
      trace('CreditsData(NULL)');
      return;
    }

    if (data.entries == null || data.entries.length == 0)
    {
      trace('CreditsData(EMPTY)');
      return;
    }

    var entryCount = data.entries.length;
    var lineCount = 0;
    for (entry in data.entries)
    {
      lineCount += entry?.body?.length ?? 0;
    }

    trace('CreditsData($entryCount entries containing $lineCount lines)');
  }

  /**
   * If for some reason the full credits won't load,
   * use this hardcoded data for the original Funkin' Crew.
   *
   * @return `CreditsData`
   */
  public static inline function getFallback():CreditsData
  {
    return {
      entries: [
        {
          header: 'Founders',
          body: [
            {line: 'ninjamuffin99'},
            {line: 'PhantomArcade'},
            {line: 'Kawai Sprite'},
            {line: 'evilsk8r'},
          ]
        }
      ]
    };
  }

  public static function fetchBackerEntries():Array<String>
  {
    // TODO: Implement a web request.
    // We can't just grab the current Kickstarter data and include it in builds,
    // because we don't want to deadname people who haven't logged into the portal yet.
    // It can be async and paginated for performance!
    return [];
  }

  #if HARDCODED_CREDITS
  /**
   * The data for the credits.
   * Hardcoded into game via a macro at compile time.
   */
  public static final CREDITS_DATA:Null<CreditsData> = #if macro null #else CreditsDataMacro.loadCreditsData() #end;
  #else

  /**
   * The data for the credits.
   * Loaded dynamically from the game folder when needed.
   * Nullable because data may fail to parse.
   */
  public static var CREDITS_DATA(get, default):Null<CreditsData> = null;

  static function get_CREDITS_DATA():Null<CreditsData>
  {
    if (CREDITS_DATA == null) CREDITS_DATA = parseCreditsData(fetchCreditsData());

    return CREDITS_DATA;
  }

  static function fetchCreditsData():funkin.data.JsonFile
  {
    #if !macro
    var rawJson:String = openfl.Assets.getText(CREDITS_DATA_PATH).trim();

    return {
      fileName: CREDITS_DATA_PATH,
      contents: rawJson
    };
    #else
    return {
      fileName: CREDITS_DATA_PATH,
      contents: null
    };
    #end
  }

  static function parseCreditsData(file:JsonFile):Null<CreditsData>
  {
    #if !macro
    if (file.contents == null) return null;

    var parser = new json2object.JsonParser<CreditsData>();
    parser.ignoreUnknownVariables = false;
    trace('[CREDITS] Parsing credits data from ${CREDITS_DATA_PATH}');
    parser.fromJson(file.contents, file.fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, file.fileName);
      return null;
    }
    return parser.value;
    #else
    return null;
    #end
  }

  static function printErrors(errors:Array<json2object.Error>, id:String = ''):Void
  {
    trace('[CREDITS] Failed to parse credits data: ${id}');

    for (error in errors)
      funkin.data.DataError.printError(error);
  }
  #end
}
