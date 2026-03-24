# Oh My Zsh Custom Plugins

Custom plugins managed as git submodules, synced into
`~/.oh-my-zsh/custom/plugins/` by `install-dotfiles.sh`.

To add a new plugin:

```bash
git submodule add https://github.com/<org>/<plugin>.git omz-custom-plugins/<plugin>
```

Then enable it in `dotfiles/.zshrc` via the `plugins=(...)` list.
