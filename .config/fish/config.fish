switch (uname)
    case Linux
        if test -d /home/linuxbrew/.linuxbrew # Linux
            set -gx HOMEBREW_PREFIX "/home/linuxbrew/.linuxbrew"
            set -gx HOMEBREW_CELLAR "$HOMEBREW_PREFIX/Cellar"
            set -gx HOMEBREW_REPOSITORY "$HOMEBREW_PREFIX/Homebrew"
        else if test -d /opt/homebrew # MacOS
            set -gx HOMEBREW_PREFIX /opt/homebrew
            set -gx HOMEBREW_CELLAR "$HOMEBREW_PREFIX/Cellar"
            set -gx HOMEBREW_REPOSITORY "$HOMEBREW_PREFIX/homebrew"
        end
        fish_add_path -gP "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"

        ! set -q MANPATH; and set MANPATH ''
        set -gx MANPATH "$HOMEBREW_PREFIX/share/man" $MANPATH

        ! set -q INFOPATH; and set INFOPATH ''
        set -gx INFOPATH "$HOMEBREW_PREFIX/share/info" $INFOPATH

        set -gx GTK_IM_MODULE ibus
        set -gx QT_IM_MODULE ibus
        set -gx XMODIFIERS @im=ibus
end

# Init services
starship init fish | source

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
