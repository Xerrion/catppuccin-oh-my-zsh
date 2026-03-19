Source tapes/config.tape
Set Theme "Catppuccin Macchiato"

Env CATPPUCCIN_FLAVOR "macchiato"

Hide
Type "source ~/.zshrc 2>/dev/null"
Enter
Sleep 1s
Type "cd /mnt/Develop/catppuccin-oh-my-zsh"
Enter
Sleep 300ms
Type "unset -m 'CATPPUCCIN_*'; export CATPPUCCIN_FLAVOR=macchiato CATPPUCCIN_PRESET=powerline CATPPUCCIN_TRANSIENT_PROMPT=false; unset BAT_THEME; source /mnt/Develop/catppuccin-oh-my-zsh/catppuccin.zsh-theme 2>&1"
Enter
Sleep 1s
Type "clear"
Enter
Sleep 300ms
Show

Type "echo 'Hello from Catppuccin Macchiato!'"
Enter
Sleep 500ms

Type "git log --oneline -5"
Enter
Sleep 500ms

Screenshot assets/macchiato.png
Sleep 1s
