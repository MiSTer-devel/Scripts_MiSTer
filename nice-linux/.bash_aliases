color_option=
less_color_option=
more_color_option=
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    color_option='--color=always'
    less_color_option='-R'
    more_color_option='-f'
fi


# TODO: move this into .bash_functions after my other PRs land.
function dir() {
    ls -FlAh "--time-style=+[%F %H:%M %Z]" --quoting-style=literal --color=always $* | sed -E 's/^([^ ]+ ) *[^ ]+ /\1/'
}

alias ls="ls --quoting-style=literal"
alias vdir="vdir $color_option"
alias less="less -R"
alias more="more -f"
alias md5sums='while IFS= read -r -d "" file; do md5sum "$file"; done < <(find * -type f -print0 | sort -s -z)'

unset color_option less_color_option more_color_option ls_quoting_option
