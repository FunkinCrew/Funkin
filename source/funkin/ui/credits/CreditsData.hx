package funkin.ui.credits;

/**
 * The members of the Funkin' Crew, organized by their roles.
 */
typedef CreditsData =
{
  var entries:Array<CreditsDataRole>;
}

/**
 * The members of a specific role on the Funkin' Crew.
 */
typedef CreditsDataRole =
{
  @:optional
  var header:String;

  @:optional
  @:default([])
  var body:Array<CreditsDataMember>;

  @:optional
  @:default(false)
  var appendBackers:Bool;
}

/**
 * A member of a specific person on the Funkin' Crew.
 */
typedef CreditsDataMember =
{
  var line:String;
}
