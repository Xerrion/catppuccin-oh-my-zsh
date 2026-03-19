Source tapes/config.tape
Set Theme "Catppuccin Mocha"

Env CATPPUCCIN_FLAVOR "mocha"

Hide
Type "source ~/.zshrc 2>/dev/null"
Enter
Sleep 2s
Type "cd /mnt/Develop/catppuccin-oh-my-zsh"
Enter
Sleep 500ms
Type "unset -m 'CATPPUCCIN_*'; export CATPPUCCIN_FLAVOR=mocha CATPPUCCIN_PRESET=powerline CATPPUCCIN_TRANSIENT_PROMPT=false; unset BAT_THEME; source /mnt/Develop/catppuccin-oh-my-zsh/catppuccin.zsh-theme 2>&1"
Enter
Sleep 2s
Type "clear"
Enter
Sleep 500ms
Show

Type "echo 'Hello from Catppuccin Mocha!'"
Enter
Sleep 1s

Type "git log --oneline -5"
Enter
Sleep 1s

Screenshot assets/mocha.png
Sleep 500ms
