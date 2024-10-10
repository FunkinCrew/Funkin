# Contributor's guide

## Cloning the repository

```sh
git clone https://github.com/FunkinCrew/Funkin.git # to clone the repo
cd funkin # to enter the project directory
```

## After cloning
You have to follow all the steps in the [compiling guide](./COMPILING.md) so the game can run on your device.

## When developing
Keep in mind to follow the [style-guide](./style-guide.md) to maintain a consistent style throughout, making the repo easier to maintain.

## When you're done doing your changes
You have to add your fork as a remote, you can do this by doing:
```sh
git remote add REMOTENAME https://github.com/YOURNAME/funkin.git
```

And then, you can commit your changes and push them to the branch `develop` or any branch you want to push to

Then you can create a pull request on github, where you'll want to merge your branch to the target branch you're pushing to

Then the Funkin developers will review your branch and approve or dissaprove/comment the changes, and eventually merge

Happy contributing!
