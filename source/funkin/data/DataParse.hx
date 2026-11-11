package funkin.data;

import funkin.data.song.importer.FNFLegacyData.LegacyNote;
import funkin.data.song.importer.FNFLegacyData.LegacyNoteData;
import funkin.data.song.importer.FNFLegacyData.LegacyNoteSection;
import funkin.data.song.importer.FNFLegacyData.LegacyScrollSpeeds;
import haxe.ds.Either;
import hxjsonast.Json;
import hxjsonast.Json.JObjectField;
import hxjsonast.Tools;
import thx.semver.Version;
import thx.semver.VersionRule;

/**
 * `json2object` has an annotation `@:jcustomparse` which allows for mutation of parsed values.
 *
 * It also allows for validation, since throwing an error in this function will cause the issue to be properly caught.
 * Parsing will fail and `parser.errors` will contain the thrown exception.
 *
 * Functions must be of the signature `(hxjsonast.Json, String) -> T`, where the String is the property name and `T` is the type of the property.
 */
@:nullSafety
class DataParse
{
  /**
   * `@:jcustomparse(funkin.data.DataParse.stringNotEmpty)`
   * @param json Contains the `pos` and `value` of the property.
   * @param name The name of the property.
   * @throws Error If the property is not a string or is empty.
   * @return The string value.
   */
  public static function stringNotEmpty(json:Json, name:String):String
  {
    switch (json.value)
    {
      case JString(s):
        if (s == '') throw 'Expected property $name to be non-empty.';
        return s;
      default:
        throw 'Expected property $name to be a string, but it was ${json.value}.';
    }
  }

  /**
   * `@:jcustomparse(funkin.data.DataParse.semverVersion)`
   * @param json Contains the `pos` and `value` of the property.
   * @param name The name of the property.
   * @return The value of the property as a `thx.semver.Version`.
   */
  public static function semverVersion(json:Json, name:String):Version
  {
    switch (json.value)
    {
      case JString(s):
        if (s == '') throw 'Expected version property $name to be non-empty.';
        return s;
      default:
        throw 'Expected version property $name to be a string, but it was ${json.value}.';
    }
  }

  /**
   * `@:jcustomparse(funkin.data.DataParse.semverVersionRule)`
   * @param json Contains the `pos` and `value` of the property.
   * @param name The name of the property.
   * @return The value of the property as a `thx.semver.VersionRule`.
   */
  public static function semverVersionRule(json:Json, name:String):VersionRule
  {
    switch (json.value)
    {
      case JString(s):
        if (s == '') throw 'Expected version rule property $name to be non-empty.';
        return s;
      default:
        throw 'Expected version rule property $name to be a string, but it was ${json.value}.';
    }
  }

  /**
   * Parser which outputs a `Either<Array<LegacyNoteSection>, LegacyNoteData>`.
   * Used by the FNF legacy JSON importer.
   */
  public static function eitherLegacyNoteData(json:Json, name:String):Either<Array<LegacyNoteSection>, LegacyNoteData>
  {
    switch (json.value)
    {
      case JArray(values):
        return Either.Left(legacyNoteSectionArray(json, name));
      case JObject(fields):
        return Either.Right(legacyNoteData(json, name));
      default:
        throw 'Expected property $name to be note data, but it was ${json.value}.';
    }
  }

  /**
   * Parser which outputs a `Either<Float, Array<Float>>`.
   */
  public static function eitherFloatOrFloats(json:Json, name:String):Null<Either<Float, Array<Float>>>
  {
    switch (json.value)
    {
      case JNumber(f):
        return Either.Left(Std.parseFloat(f));
      case JArray(fields):
        return Either.Right(fields.map((field) -> cast Tools.getValue(field)));
      default:
        throw 'Expected property $name to be one or multiple floats, but it was ${json.value}.';
    }
  }

  public static function backdropData(json:Json, name:String):funkin.data.dialogue.ConversationData.BackdropData
  {
    switch (json.value)
    {
      case JObject(fields):
        var result:Dynamic = {};
        var backdropType:String = '';

        for (field in fields)
        {
          switch (field.name)
          {
            case 'type':
              backdropType = Tools.getValue(field.value);
          }
          Reflect.setField(result, field.name, Tools.getValue(field.value));
        }

        switch (backdropType)
        {
          case 'solid':
            return SOLID(result);
          default:
            throw 'Expected Backdrop property $name to be specify a valid "type", but it was "${backdropType}".';
        }

      default:
        throw 'Expected property $name to be an object, but it was ${json.value}.';
    }
  }

  public static function outroData(json:Json, name:String):Null<funkin.data.dialogue.ConversationData.OutroData>
  {
    switch (json.value)
    {
      case JObject(fields):
        var result:Dynamic = {};
        var outroType:String = '';

        for (field in fields)
        {
          switch (field.name)
          {
            case 'type':
              outroType = Tools.getValue(field.value);
          }
          Reflect.setField(result, field.name, Tools.getValue(field.value));
        }

        switch (outroType)
        {
          case 'none':
            return NONE(result);
          case 'fade':
            return FADE(result);
          default:
            throw 'Expected Outro property $name to be specify a valid "type", but it was "${outroType}".';
        }
        return null;
      default:
        throw 'Expected property $name to be an object, but it was ${json.value}.';
    }
  }

  /**
   * Parser which outputs a `Either<Float, LegacyScrollSpeeds>`.
   * Used by the FNF legacy JSON importer.
   */
  public static function eitherLegacyScrollSpeeds(json:Json, name:String):Either<Float, LegacyScrollSpeeds>
  {
    switch (json.value)
    {
      case JNumber(f):
        return Either.Left(Std.parseFloat(f));
      case JObject(fields):
        return Either.Right(cast Tools.getValue(json));
      default:
        throw 'Expected property $name to be scroll speeds, but it was ${json.value}.';
    }
  }

  /**
   * Array of JSON fields `[{key, value}, {key, value}]` to a Dynamic object `{key:value, key:value}`.
   * @param fields
   * @return Dynamic
   */
  static function jsonFieldsToDynamicObject(fields:Array<JObjectField>):Dynamic
  {
    var result:Dynamic = {};
    for (field in fields)
    {
      Reflect.setField(result, field.name, Tools.getValue(field.value));
    }
    return result;
  }

  /**
   * Array of JSON elements `[Json, Json, Json]` to a Dynamic array `[String, Object, Int, Array]`
   * @param jsons
   * @return Array<Dynamic>
   */
  static function jsonArrayToDynamicArray(jsons:Array<Json>):Array<Null<Dynamic>>
  {
    return[for (json in jsons) Tools.getValue(json)];
  }

  /**
   * Array of JSON fields `[{key, value}, {key, value}]` to a Map of arrays of dynamic objects.
   * @param fields
   * @return An output like [{key: [String, String]}, {key: [Int, Int]}]
   */
  static function jsonFieldsToDynamicArrayMap(fields:Array<JObjectField>):Null<Map<String, Array<Dynamic>>>
  {
    var result:Map<String, Array<Null<Dynamic>>> = [];
    for (field in fields)
    {
      switch (field.value.value)
      {
        case JArray(values):
          result.set(field.name, jsonArrayToDynamicArray(values));
        default:
          throw 'Expected property to be an array, but it was ${field.value}.';
      }
    }
    return result;
  }


  /**
   * Parses the notes of a chart by hand.
   */
  public static function songNotesMap(json:Json, name:String):Map<String, Array<funkin.data.song.SongData.SongNoteData>>
  {
    switch (json.value)
    {
      case JObject(fields):
        var result:Map<String, Array<funkin.data.song.SongData.SongNoteData>> = [];
        for (field in fields)
        {
          switch (field.value.value)
          {
            case JArray(values):
              result.set(field.name, [for (value in values) songNote(value, field.name)]);
            default:
              throw 'Expected property $name.${field.name} to be an array of notes, but it was ${field.value.value}.';
          }
        }
        return result;
      default:
        throw 'Expected property $name to be a map, but it was ${json.value}.';
    }
  }

  /**
   * Parses a JSON field as a map of arrays of dynamic objects.
   */
  static function songNote(json:Json, name:String):funkin.data.song.SongData.SongNoteData
  {
    switch (json.value)
    {
      case JObject(fields):
        var time:Null<Float> = null;
        var data:Null<Int> = null;
        var length:Float = 0;
        var kind:Null<String> = null;
        var params:Array<funkin.data.song.SongData.NoteParamData> = [];
        for (field in fields)
        {
          switch (field.name)
          {
            case 't':
              time = jsonFloat(field.value, 't');
            case 'd':
              data = Std.int(jsonFloat(field.value, 'd'));
            case 'l':
              length = jsonFloat(field.value, 'l');
            case 'k':
              switch (field.value.value)
              {
                case JString(value):
                  kind = value;
                case JNull:
                  kind = null;
                default:
                  throw 'Expected note kind in $name to be a string, but it was ${field.value.value}.';
              }
            case 'p':
              switch (field.value.value)
              {
                case JArray(values):
                  params = [for (value in values) noteParam(value, name)];
                case JNull:
                  params = [];
                default:
                  throw 'Expected note params in $name to be an array, but it was ${field.value.value}.';
              }
            default:
          }
        }
        if (time == null) throw 'A note in $name is missing its time (t).';
        if (data == null) throw 'A note in $name is missing its direction (d).';
        return new funkin.data.song.SongData.SongNoteData(time, data, length, kind ?? '', params);
      default:
        throw 'Expected a note in $name to be an object, but it was ${json.value}.';
    }
  }

  static function noteParam(json:Json, name:String):funkin.data.song.SongData.NoteParamData
  {
    switch (json.value)
    {
      case JObject(fields):
        var paramName:Null<String> = null;
        var paramValue:Dynamic = null;
        for (field in fields)
        {
          switch (field.name)
          {
            case 'n':
              paramName = Tools.getValue(field.value);
            case 'v':
              paramValue = Tools.getValue(field.value);
            default:
          }
        }
        if (paramName == null) throw 'A note param in $name is missing its name (n).';
        return new funkin.data.song.SongData.NoteParamData(paramName, paramValue);
      default:
        throw 'Expected a note param in $name to be an object, but it was ${json.value}.';
    }
  }

  static function jsonFloat(json:Json, name:String):Float
  {
    switch (json.value)
    {
      case JNumber(value):
        return Std.parseFloat(value);
      default:
        throw 'Expected property $name to be a number, but it was ${json.value}.';
    }
  }

  public static function dynamicArrayMap(json:Json, name:String):Null<Map<String, Array<Dynamic>>>
  {
    switch (json.value)
    {
      case JObject(fields):
        return jsonFieldsToDynamicArrayMap(fields);
      default:
        throw 'Expected property $name to be a map, but it was ${json.value}.';
    }
  }

  static function legacyNoteSectionArray(json:Json, name:String):Array<LegacyNoteSection>
  {
    switch (json.value)
    {
      case JArray(values):
        return[for (value in values) legacyNoteSection(value, name)];
      default:
        throw 'Expected property to be an array, but it was ${json.value}.';
    }
  }

  static function legacyNoteSection(json:Json, name:String):LegacyNoteSection
  {
    switch (json.value)
    {
      case JObject(fields):
        var result:LegacyNoteSection = {
          mustHitSection: false,
          sectionNotes: [],
        };
        for (field in fields)
        {
          switch (field.name)
          {
            case 'sectionNotes':
              result.sectionNotes = legacyNotes(field.value, field.name);

            case 'mustHitSection':
              result.mustHitSection = Tools.getValue(field.value);
            case 'typeOfSection':
              result.typeOfSection = Tools.getValue(field.value);
            case 'lengthInSteps':
              result.lengthInSteps = Tools.getValue(field.value);
            case 'changeBPM':
              result.changeBPM = Tools.getValue(field.value);
            case 'bpm':
              result.bpm = Tools.getValue(field.value);
          }
        }
        return result;
      default:
        throw 'Expected property $name to be an object, but it was ${json.value}.';
    }
  }

  public static function legacyNoteData(json:Json, name:String):LegacyNoteData
  {
    switch (json.value)
    {
      case JObject(fields):
        var result = {};
        for (field in fields)
        {
          Reflect.setField(result, field.name, legacyNoteSectionArray(field.value, field.name));
        }
        return result;
      default:
        throw 'Expected property $name to be an object, but it was ${json.value}.';
    }
  }

  public static function legacyNotes(json:Json, name:String):Array<LegacyNote>
  {
    switch (json.value)
    {
      case JArray(values):
        return[for (value in values) legacyNote(value, name)];
      default:
        throw 'Expected property $name to be an array of notes, but it was ${json.value}.';
    }
  }

  public static function legacyNote(json:Json, name:String):LegacyNote
  {
    switch (json.value)
    {
      case JArray(values):
        var time:Null<Float> = values[0] == null ? null : Tools.getValue(values[0]);
        var data:Null<Int> = values[1] == null ? null : Tools.getValue(values[1]);
        var length:Null<Float> = values[2] == null ? null : Tools.getValue(values[2]);
        var alt:Null<Bool> = values[3] == null ? null : Tools.getValue(values[3]);

        if (time == null || data == null) throw 'Property $name note is missing time and/or data values.';
        return new LegacyNote(time, data, length, alt);
      // return null;
      default:
        throw 'Expected property $name to be a note, but it was ${json.value}.';
    }
  }
}
