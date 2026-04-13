# homebrew-orttaai

Homebrew tap for installing Orttaai.

## Install

```bash
brew tap theoyinbooke/orttaai
brew install --cask theoyinbooke/orttaai/orttaai
```

## Upgrade

```bash
brew update
brew upgrade --cask theoyinbooke/orttaai/orttaai
```

## Release maintenance

Update the cask for a new Orttaai release with one command:

```bash
./scripts/bump-cask.sh --version 1.0.11 --download
```

If you already have the DMG locally, hash that file instead:

```bash
./scripts/bump-cask.sh --version 1.0.11 --file ~/Downloads/Orttaai-1.0.11.dmg
```

The script updates `Casks/orttaai.rb` in place.
