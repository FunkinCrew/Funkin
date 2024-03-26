package funkin.ui.credits;

/**
 * The members of the Funkin' Crew, organized by their roles.
 */
typedef CreditsData =
{
  var roles:Array<CreditsDataRole>;
}

/**
 * The members of a specific role on the Funkin' Crew.
 */
typedef CreditsDataRole =
{
  var roleName:String;
  var members:Array<CreditsDataMember>;
}

/**
 * A member of a specific person on the Funkin' Crew.
 */
typedef CreditsDataMember =
{
  var fullName:String;
}
