"""Turns a GameBanana submission URL into a `funkin:` one-click install link.

Usage:
  python genOneClickLink.py https://gamebanana.com/mods/700143
  python genOneClickLink.py 700143
"""

import json
import re
import sys
import urllib.error
import urllib.request

API_URL = "https://gamebanana.com/apiv11/{model}/{itemId}/ProfilePage"

CATEGORIES_URL = "https://gamebanana.com/apiv11/Mod/Categories?_sSort=a_to_z&_bShowEmpty=true&_idCategoryRow={categoryId}"

CATEGORY_ROOT = 29202

USER_AGENT = "FunkinOneClickLink/1.0"

MODELS = {
  "mods": "Mod",
  "sounds": "Sound",
  "wips": "Wip",
  "tools": "Tool",
}

URL_PATTERN = re.compile(r"gamebanana\.com/([a-z]+)/(?:download/)?(\d+)", re.IGNORECASE)


def parseTarget(value):
  """Pulls the model name and submission id out of whatever was pasted."""
  value = value.strip()

  if value.isdigit():
    return "Mod", value

  match = URL_PATTERN.search(value)

  if match is None:
    return "Mod", None

  return MODELS.get(match.group(1).lower(), "Mod"), match.group(2)


def fetchJson(url):
  request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})

  with urllib.request.urlopen(request) as response:
    return json.load(response)


def fetchProfile(model, itemId):
  return fetchJson(API_URL.format(model=model, itemId=itemId))


def fetchModFolderCategories():
  """The category ids that count as a base game mod folder, root included.
  """
  children = fetchJson(CATEGORIES_URL.format(categoryId=CATEGORY_ROOT))

  return {CATEGORY_ROOT} | {entry["_idRow"] for entry in children}


def main():
  if len(sys.argv) < 2:
    print("Usage: genOneClickLink.py <gamebanana url or submission id>", file=sys.stderr)
    return 1

  model, itemId = parseTarget(sys.argv[1])

  if itemId is None:
    print(f'Could not find a submission id in "{sys.argv[1]}".', file=sys.stderr)
    return 1

  try:
    profile = fetchProfile(model, itemId)
    allowed = fetchModFolderCategories()
  except (urllib.error.URLError, json.JSONDecodeError, KeyError) as error:
    print(f"Failed to reach GameBanana: {error}", file=sys.stderr)
    return 1

  name = profile.get("_sName", "Unknown")
  files = profile.get("_aFiles") or []

  if not files:
    print(f'"{name}" has no downloadable files.', file=sys.stderr)
    return 1

  category = profile.get("_aCategory") or {}
  superCategory = profile.get("_aSuperCategory") or {}
  categoryName = category.get("_sName", "Unknown")
  isModFolder = category.get("_idRow") in allowed or superCategory.get("_idRow") in allowed

  print(f"{name} ({model} {itemId})")
  print(f"Category: {categoryName}")

  for requirement in profile.get("_aRequirements") or []:
    label = requirement[0] if requirement else "?"
    url = requirement[1] if len(requirement) > 1 else ""
    _, requiredId = parseTarget(url)

    print(f'Needs: {label}' + ("" if requiredId else "  (no submission link, will be skipped)"))

  if not isModFolder:
    print()
    print(f'WARNING: "{categoryName}" is not a base game mod folder category.')
    print("The game will refuse this link.")

  print()

  # The item id names the submission, the file id picks which of its files to grab.
  for entry in files:
    megabytes = entry.get("_nFilesize", 0) / 1024 / 1024

    print(f'{entry.get("_sFile", "?")} ({megabytes:.1f} MB)')
    print(f'funkin:https://gamebanana.com/mmdl/{entry["_idRow"]},{model},{itemId}')
    print()

  return 0


if __name__ == "__main__":
  sys.exit(main())
