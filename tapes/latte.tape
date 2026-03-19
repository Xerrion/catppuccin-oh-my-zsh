Source tapes/config.tape
Set Theme "Catppuccin Latte"

Env CATPPUCCIN_FLAVOR "latte"

Hide
Type "source ~/.zshrc 2>/dev/null"
Enter
Sleep 2s
Type "cd /mnt/Develop/catppuccin-oh-my-zsh"
Enter
Sleep 500ms
Type "unset -m 'CATPPUCCIN_*'; export CATPPUCCIN_FLAVOR=latte CATPPUCCIN_PRESET=powerline CATPPUCCIN_TRANSIENT_PROMPT=false; unset BAT_THEME; source /mnt/Develop/catppuccin-oh-my-zsh/catppuccin.zsh-theme 2>&1"
Enter
Sleep 2s
Type "clear"
Enter
Sleep 500ms
Show

Type "echo 'Hello from Catppuccin Latte!'"
Enter
Sleep 1s

Type "git log --oneline -5"
Enter
Sleep 1s

Screenshot assets/latte.png
Sleep 500ms
