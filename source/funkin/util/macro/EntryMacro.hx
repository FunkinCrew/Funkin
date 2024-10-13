package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

class EntryMacro
{
  public static macro function build(registryExpr:ExprOf<Class<Dynamic>>):Array<Field>
  {
    var fields = Context.getBuildFields();

    var cls = Context.getLocalClass().get();

    var registryCls = MacroUtil.getClassTypeFromExpr(registryExpr);

    fields.push(build_fetchDataField(registryExpr));

    return fields;
  }

  #if macro
  static function build_fetchDataField(registryExpr:ExprOf<Class<Dynamic>>):Field
  {
    return {
      name: '_fetchData',
      access: [Access.APrivate],
      kind: FieldType.FFun(
        {
          args: [
            {
              name: 'id',
              type: (macro :String)
            }
          ],
          expr: macro
          {
            var result = ${registryExpr}.instance.parseEntryDataWithMigration(id, ${registryExpr}.instance.fetchEntryVersion(id));

            if (result == null)
            {
              throw 'Could not parse note style data for id: ' + id;
            }
            else
            {
              return result;
            }
          },
          params: [],
          ret: (macro :funkin.data.notestyle.NoteStyleData)
        }),
      pos: Context.currentPos()
    };

    /**
      *   static function _fetchData(id:String):NoteStyleData
      {
        var result = NoteStyleRegistry.instance.parseEntryDataWithMigration(id, NoteStyleRegistry.instance.fetchEntryVersion(id));

        if (result == null)
        {
          throw 'Could not parse note style data for id: $id';
        }
        else
        {
          return result;
        }
      }
     */
  }
  #end
}
