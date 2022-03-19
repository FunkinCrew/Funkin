package funkin.i18n;

import firetongue.FireTongue;

class FireTongueHandler
{
	static final DEFAULT_LOCALE = 'en-US';
	// static final DEFAULT_LOCALE = 'pt-BR';
	static final LOCALE_DIR = 'assets/locales/';

	static var tongue:FireTongue;

	/**
	 * Initialize the FireTongue instance.
	 * This will automatically start with the default locale for you.
	 */
	public static function init():Void
	{
		tongue = new FireTongue(OPENFL, // Haxe framework being used.
			// This should really have been a parameterized object...
			null, // Function to check if a file exists. Specify null to use the one from the framework.
			null, // Function to retrieve the text of a file.	Specify null to use the one from the framework.
			null, // Function to get a list of files in a directory. Specify null to use the one from the framework.
			firetongue.FireTongue.Case.Upper);

		// TODO: Make this use the language from the user's preferences.
		setLanguage(DEFAULT_LOCALE);

		trace('[FIRETONGUE] Initialized. Available locales: ${tongue.locales.join(', ')}');
	}

	/**
	 * Switch the language used by FireTongue.
	 * @param locale The name of the locale to use, such as `en-US`.
	 */
	public static function setLanguage(locale:String):Void
	{
		tongue.initialize({
			locale: locale, // The locale to load.

			finishedCallback: onFinishLoad, // Function run when the locale is loaded.
			directory: LOCALE_DIR, // Folder (relative to assets/) to load data from.
			replaceMissing: false, // If true, missing flags fallback to the default locale.
			checkMissing: true, // If true, check for and store the list of missing flags for this locale.
		});
	}

	/**
	 * Function called when FireTongue finishes loading a language.
	 */
	static function onFinishLoad()
	{
		if (tongue == null)
			return;

		trace('[FIRETONGUE] Finished loading locale: ${tongue.locale}');
		if (tongue.missingFlags != null)
		{
			if (tongue.missingFlags.get(tongue.locale) != null && tongue.missingFlags.get(tongue.locale).length != 0)
			{
				trace('[FIRETONGUE] Missing flags: ${tongue.missingFlags.get(tongue.locale).join(', ')}');
			}
			else
			{
				trace('[FIRETONGUE] No missing flags for this locale. (Note: Another locale has missing flags.)');
			}
		}
		else
		{
			trace('[FIRETONGUE] No missing flags.');
		}

		trace('[FIRETONGUE] HELLO_WORLD = ${t("HELLO_WORLD")}');
	}

	/**
	 * Retrieve a localized string based on the given key.
	 * 
	 * Example:
	 * import i18n.FiretongueHandler.t;
	 * trace(t('HELLO')); // Prints "Hello!"
	 * 
	 * @param key The key to use to retrieve the localized string.
	 * @param context The data file to load the key from.
	 * @return The localized string.
	 */
	public static function t(key:String, context:String = 'data'):String
	{
		// The localization strings can be stored all in one file,
		// or split into several contexts.
		return tongue.get(key, context);
	}

	/**
	 * Retrieve a localized string while replacing specific values.
	 * In this way, you can use the same invocation call to properly localize
	 * a variety of different languages with distinct grammar.
	 * 
	 * Example:
	 * import i18n.FiretongueHandler.f;
	 * trace(f('COLLECT_X_APPLES', 'data', ['<X>'], ['10']); // Prints "Collect 10 apples!"
	 * 
	 * @param key The key to use to retrieve the localized string.
	 * @param context The data file to load the key from.
	 * @param flags The flags to replace in the string.
	 * @param values The values to replace those flags with.
	 * @return The localized string.
	 */
	public static function f(key:String, context:String = 'data', flags:Array<String> = null, values:Array<String> = null):String
	{
		var str = t(key, context);
		return firetongue.Replace.flags(str, flags, values);
	}
}
