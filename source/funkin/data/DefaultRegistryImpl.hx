package funkin.data;

/**
 * An interface which automatically implements essential fields for a class extending `BaseRegistry`.
 *
 * @see `funkin.data.BaseRegistry`
 */
@:autoBuild(funkin.util.macro.RegistryMacro.buildRegistry())
interface DefaultRegistryImpl {}
