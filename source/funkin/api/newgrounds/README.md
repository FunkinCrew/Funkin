# funkin.api.newgrounds

This package contains two main classes:
- `NGUtil` contains utility functions for interacting with the Newgrounds API.
  - This includes any functions which scripts should be able to use,
		such as retrieving achievement status.
- `NGUnsafe` contains sensitive utility functions for interacting with the Newgrounds API.
	- This includes any functions which scripts should not be able to use,
		such as writing high scores or posting achievements.
