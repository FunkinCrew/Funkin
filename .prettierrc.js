/**
 * Configuration for JSON file formatting.
 */
module.exports = {
  // Line width before Prettier tries to add new lines.
  printWidth: 80,

	// Indent with 2 spaces.
	tabs: false,
  useTabs: false,
  tabWidth: 2,

  // Use double quotes.
  singleQuote: false,
  quoteProps: "preserve",
  parser: "json",

  bracketSpacing: true, // Spacing between brackets in object literals.
  trailingComma: "none", // No trailing commas.
  semi: false, // No semicolons at ends of statements.
};