# Installing and Setting Up Python #

## OSX ##

### Getting OSX Ready ###

- `xcode-select --install`
- `softwareupdate --all --install --force`

#### Install Homebrew ####

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update
```

#### Installing Pyenv ####

```bash
brew install pyenv
brew install pyenv-virtualenv
```

Follow instructions from [Pyenv Github](https://github.com/pyenv/pyenv#set-up-your-shell-environment-for-pyenv) look for the zsh section  

Make sure you have the dependencies for OSX mentioned [here](https://github.com/pyenv/pyenv/wiki#suggested-build-environment)  

[How To Use Pyenv](https://github.com/pyenv/pyenv#usage)  

[VSCode Instructions Of How To Use Them](https://code.visualstudio.com/docs/python/environments)  
