# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git fzf zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export PATH="$HOME/.local/bin:$PATH"
eval "$(zoxide init zsh)"
# Navigare ultra-rapidă cu zoxide
alias j='z'
alias ji='zi' # Deschide un meniu interactiv (fzf) pentru folderele vizitate

# Înlocuitori moderni (dacă ai instalat eza și bat)
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias cat='bat'

# Utilitare pentru fișiere
alias ..='cd ..'
alias ...='cd ../..'
eval "$(starship init zsh)"

# Pornirea bannerului tău de salut
~/vremea.sh

radio() {
  local mode="country"
  local query="romania"
  local socket="/tmp/mpv-radio-socket" # Canalul de comunicare cu mpv
  
  case "$1" in
    -g) mode="tag"; query="$2" ;;
    -t) mode="country"; query="$2" ;;
    *) query="${1:-romania}" ;;
  esac

  pkill -f mpv >/dev/null 2>&1
  local title_file="/tmp/radio_title.txt"
  echo "Se încarcă..." > "$title_file"

  while true; do
    local url_api=""
    if [[ "$mode" == "tag" ]]
        then
            # Căutare după tag (gen muzical)
            url_api="https://all.api.radio-browser.info/json/stations/search?tag=${query}&limit=5000&order=clickcount&reverse=true"
        else
            # Căutare după țară (default romania)
            url_api="https://all.api.radio-browser.info/json/stations/bycountry/${query}?limit=5000"
        fi

    clear
    echo "🔍 Se descarcă lista..."
    local choice=$(curl -sL "$url_api" | jq -r '.[] | "\(.name) [\(.countrycode)] [\(.tags | split(",") | .[0:2] | join(", "))]|\(.url_resolved)"' | fzf --reverse)

    [[ -z "$choice" ]] && { pkill -f mpv; rm -f "$title_file" "$socket"; clear; return }

    local name=$(echo "$choice" | cut -d'|' -f1)
    local url=$(echo "$choice" | cut -d'|' -f2)

    pkill -f mpv >/dev/null 2>&1
    # MODIFICARE: Am scos 'disown' pentru a preveni blocarea driverului video. 
    # Procesul ramane in fundal prin '&', dar ramane controlabil de sistem.
    (mpv --no-video --input-ipc-server="$socket" --msg-level=all=status --term-status-msg='${media-title}' "$url" > "$title_file" 2>&1 &)

    clear
    printf "\e[?25l" # Ascunde cursorul

    while true; do
      printf "\e[1;1H"
      echo "📻 POST: ${name:0:50}                                "
      echo "-------------------------------------------------------"
      local current_song=$(tail -n 1 "$title_file" | sed 's/\r//g')
      printf "🎵 MELODIE: %-50s\e[K\n" "${current_song:-Informații...}"
      echo "-------------------------------------------------------"
      echo "👉 [p] Pauză/Play  | [m] Mute     | [0/9] Volum +/-   "
      echo "👉 [s] Alt POST    | [q] OPRIRE                       "
      echo "-------------------------------------------------------"

      # Citim tasta apăsată (fără ENTER)
      if read -k 1 -t 2 key; then
        case "$key" in
          p) echo '{ "command": ["cycle", "pause"] }' | socat - "$socket" >/dev/null 2>&1 ;;
          m) echo '{ "command": ["cycle", "mute"] }' | socat - "$socket" >/dev/null 2>&1 ;;
          9) echo '{ "command": ["add", "volume", -5] }' | socat - "$socket" >/dev/null 2>&1 ;;
          0) echo '{ "command": ["add", "volume", 5] }' | socat - "$socket" >/dev/null 2>&1 ;;
          s) printf "\e[?25h"; break ;;
          q) printf "\e[?25h"; pkill -f mpv; rm -f "$title_file" "$socket"; clear; return ;;
        esac
      fi
    done
  done
}

ytplay() {
    pkill -9 mpv > /dev/null 2>&1
    
    while true; do
        echo "🔍 Căutare YouTube: $1..."
        local choice=$(yt-dlp "ytsearch100:$1" --flat-playlist --print "%(id)s %(title)s" --no-warnings | fzf --reverse --header "Alege melodia (ESC pentru ieșire)")
        
        [[ -z "$choice" ]] && break

        local video_id=$(echo "$choice" | awk '{print $1}')
        local video_title=$(echo "$choice" | cut -d' ' -f2-)
        local video_url="https://www.youtube.com/watch?v=$video_id"

        local sub_menu=true
        while [ "$sub_menu" = true ]; do
            echo -e "\n🎬 Opțiuni pentru: $video_title"
            echo "------------------------------------------"
            echo "[1] Redare Video"
            echo "[2] Download MP3"
            echo "[3] Download Video"
            echo "[4] Înapoi la listă"
            echo -n "Alegere (1-4): "
            read -r action

            case $action in
                1)
                    echo "🚀 Pornesc playerul..."
                    mpv --force-window --gpu-context=wayland --vo=gpu-next --hwdec=no --ytdl-format="bestvideo[height<=1080][vcodec!=av1]+bestaudio/best" "$video_url"
                    --ytdl-raw-options="cookies-from-browser=chrome" \
                    ;;
                2)
                    echo "🎵 Descarc MP3 în ~/Downloads..."
                    yt-dlp -x --audio-format mp3 --no-warnings -o "~/Downloads/%(title)s.%(ext)s" "$video_url"
                    echo "✅ Gata! MP3 salvat."
                    ;;
                3)
    echo "🎥 Descarc Video la CALITATE MAXIMĂ în ~/Downloads..."
    yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 --no-warnings -o "~/Downloads/%(title)s.%(ext)s" "$video_url"
    echo "✅ Gata! Video salvat la calitate de top."
    ;;
                    
                4)
                    sub_menu=false # Te întoarce la lista fzf
                    clear
                    ;;
                *)
                    echo "❌ Opțiune invalidă."
                    ;;
            esac
        done
    done
    clear
}

alias vreme='~/vremea.sh'
alias gpu='nvidia-smi --query-gpu=pstate,utilization.gpu,clocks.gr,temperature.gpu --format=csv,noheader'
alias updateall='sudo apt clean && sudo apt update && sudo apt upgrade -y && flatpak update -y && sudo yt-dlp -U'
alias cleanall='sudo apt autoremove --purge -y && sudo apt autoclean && sudo dpkg -l | grep "^rc" | awk "{print \$2}" | xargs -r sudo dpkg --purge && flatpak uninstall --unused -y && sudo journalctl --vacuum-time=2d && rm -rf ~/.cache/thumbnails/* && rm -rf ~/.cache/ranger/*'

alias btm='btm'
export PATH="$HOME/.cargo/bin:$PATH"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
