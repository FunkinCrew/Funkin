package funkin.util.tools;

/**
 * An interface which applies a macro to add a Singleton `instance` property to the class.
 */
@:autoBuild(funkin.util.macro.SingletonMacro.build())
interface ISingleton {}
