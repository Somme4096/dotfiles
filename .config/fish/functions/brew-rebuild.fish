function brew-rebuild --wraps='brew bundle install --force --global' --description 'alias brew-rebuild=brew bundle install --force --global'
    brew bundle install --force --force-cleanup --global $argv
end
