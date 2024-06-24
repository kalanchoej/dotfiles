#!/bin/sh

#                    _           _        _ _
#  ___  _____  __   (_)_ __  ___| |_ __ _| | |
# / _ \/ __\ \/ /   | | '_ \/ __| __/ _` | | |
#| (_) \__ \>  <    | | | | \__ \ || (_| | | |
# \___/|___/_/\_\   |_|_| |_|___/\__\__,_|_|_|


echo "Mac OS Install Setup Script"
echo "By Nina Zakharenko"

# Some configs reused from:
# https://github.com/ruyadorno/installme-osx/
# https://gist.github.com/millermedeiros/6615994
# https://gist.github.com/brandonb927/3195465/

# Colorize

# Set the colours you can use
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)

# Resets the style
reset=`tput sgr0`

# Color-echo. Improved. [Thanks @joaocunha]
# arg $1 = message
# arg $2 = Color
cecho() {
  echo "${2}${1}${reset}"
  return
}

echo ""
cecho "###############################################" $red
cecho "#        DO NOT RUN THIS SCRIPT BLINDLY       #" $red
cecho "#         YOU'LL PROBABLY REGRET IT...        #" $red
cecho "#                                             #" $red
cecho "#              READ IT THOROUGHLY             #" $red
cecho "#         AND EDIT TO SUIT YOUR NEEDS         #" $red
cecho "###############################################" $red
echo ""

# Set continue to false by default.
CONTINUE=false

echo ""
cecho "Have you read through the script you're about to run and " $red
cecho "understood that it will make changes to your computer? (y/n)" $red
read -r response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  CONTINUE=true
fi

if ! $CONTINUE; then
  # Check if we're continuing and output a message if not
  cecho "Please go read the script, it only takes a few minutes" $red
  exit
fi

# Here we go.. ask for the administrator password upfront and run a
# keep-alive to update existing `sudo` time stamp until script has finished
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


##############################
# Prerequisite: Install Brew #
##############################

echo "Installing brew..."

if test ! $(which brew)
then
	## Don't prompt for confirmation when installing homebrew
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null
fi

# Latest brew, install brew cask
brew upgrade
brew update
brew tap caskroom/cask


#############################################
### Generate ssh keys & add to ssh-agent
### See: https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/
#############################################

echo "Generating ssh keys, adding to ssh-agent..."
read -p 'Input email for ssh key: ' useremail

echo "Use default ssh file location, enter a passphrase: "
ssh-keygen -t rsa -b 4096 -C "$useremail"  # will prompt for password
eval "$(ssh-agent -s)"

# Now that sshconfig is synced add key to ssh-agent and
# store passphrase in keychain
ssh-add -K ~/.ssh/id_rsa

# If you're using macOS Sierra 10.12.2 or later, you will need to modify your ~/.ssh/config file to automatically load keys into the ssh-agent and store passphrases in your keychain.

if [ -e ~/.ssh/config ]
then
    echo "ssh config already exists. Skipping adding osx specific settings... "
else
	echo "Writing osx specific settings to ssh config... "
   cat <<EOT >> ~/.ssh/config
	Host *
		AddKeysToAgent yes
		UseKeychain yes
		IdentityFile ~/.ssh/id_rsa
EOT
fi

#############################################
### Add ssh-key to GitHub via api
#############################################

echo "Adding ssh-key to GitHub (via api)..."
echo "Important! For this step, use a github personal token with the admin:public_key permission."
echo "If you don't have one, create it here: https://github.com/settings/tokens/new"

retries=3
SSH_KEY=`cat ~/.ssh/id_rsa.pub`

for ((i=0; i<retries; i++)); do
      read -p 'GitHub username: ' ghusername
      read -p 'Machine name: ' ghtitle
      read -sp 'GitHub personal token: ' ghtoken

      gh_status_code=$(curl -o /dev/null -s -w "%{http_code}\n" -u "$ghusername:$ghtoken" -d '{"title":"'$ghtitle'","key":"'"$SSH_KEY"'"}' 'https://api.github.com/user/keys')

      if (( $gh_status_code -eq == 201))
      then
          echo "GitHub ssh key added successfully!"
          break
      else
			echo "Something went wrong. Enter your credentials and try again..."
     		echo -n "Status code returned: "
     		echo $gh_status_code
      fi
done

[[ $retries -eq i ]] && echo "Adding ssh-key to GitHub failed! Try again later."


##############################
# Install via Brew           #
##############################

echo "Starting brew app install..."

### Window Management
# # Todo: think about using rectangle
# brew install --cask sizeup  # window manager

# # Start SizeUp at login
# defaults write com.irradiatedsoftware.SizeUp StartAtLogin -bool true

# # Don’t show the preferences window on next start
# defaults write com.irradiatedsoftware.SizeUp ShowPrefsOnNextStart -bool false


### Developer Tools
brew install iterm2
# brew install asciinema
brew install ispell
brew install postman
# brew install akamai
brew install ttyd
brew install gpg
# brew install serverless
# brew install pyenv-virtualenv


### Development
# brew install --cask docker # Need to install docker from JAMF
#brew install postgresql
#brew install redis


### Command line tools - install new ones, update others to latest version
brew install git  # upgrade to latest
brew install git-lfs # track large files in git https://github.com/git-lfs/git-lfs
brew install wget
brew install zsh # zshell
brew install tmux
brew install tree
brew link curl --force
#brew install the_silver_searcher
brew install fzf
brew install gsed
brew install trash  # move to osx trash instead of rm
brew install less
brew install thefuck
brew install imagemagick

#Atuin and other CLI magics
# bash <(curl https://raw.githubusercontent.com/ellie/atuin/main/install.sh)
# atuin import auto
brew install zoxide
echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
brew install fzf
$(brew --prefix)/opt/fzf/install --key-bindings --completion --update-rc
brew install bat
brew install fd

### Python
brew install python
#brew install pyenv
brew install openssl
brew link openssl --force


### Microcontrollers & Electronics
#brew install avrdude
#brew install --cask arduino
# Manually install teensyduino from:
# https://www.pjrc.com/teensy/td_download.html


### Dev Editors
brew install visual-studio-code
#brew install --cask pycharm
### spacemacs github.com/syl20bnr/spacemacs
#git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
#brew tap d12frosted/emacs-plus
#brew install emacs-plus --HEAD --with-natural-title-bars
#brew linkapps emacs-plus


### Writing
#brew install --cask evernote
#brew install --cask macdown
#brew install --cask notion


### Conferences, Blogging, Screencasts
#brew install --cask deckset
#brew install --cask ImageOptim  # for optimizing images
#brew install --cask screenflow


### Productivity
#brew install --cask wavebox
#brew install --cask google-chrome
#brew install --cask alfred
#brew install --cask dropbox
brew install --cask arc #arc web browser

#brew install --cask timing  # time and project tracker
#brew install --cask keycastr  # show key presses on screen (for gifs & screencasts)
brew install --cask betterzip
#brew install --cask caffeine  # keep computer from sleeping
brew install --cask skitch  # app to annotate screenshots
#brew install --cask muzzle
#brew install --cask flux


### Keyboard & Mouse
#brew install --cask karabiner-elements  # remap keys, emacs shortcuts
#brew install --cask scroll-reverser  # allow natural scroll for trackpad, not for mouse


### Quicklook plugins https://github.com/sindresorhus/quick-look-plugins
brew install --cask qlcolorcode # syntax highlighting in preview
brew install --cask qlstephen  # preview plaintext files without extension
brew install --cask qlmarkdown  # preview markdown files
brew install --cask quicklook-json  # preview json files
#brew install --cask epubquicklook  # preview epubs, make nice icons
brew install --cask quicklook-csv  # preview csvs


### Chat / Video Conference
#brew install --cask slack
brew install discord
brew install keybase
#brew install --cask microsoft-teams
#brew install --cask zoomus
#brew install --cask signal


### Music and Video
#brew install --cask yt-music
brew install --cask vlc


### Run Brew Cleanup
brew cleanup


#############################################
### Fonts
#############################################

echo "Installing fonts..."

brew tap caskroom/fonts

### programming fonts
brew install --cask font-fira-mono-for-powerline
brew install --cask font-fira-code

### SourceCodePro + Powerline + Awesome Regular (for powerlevel 9k terminal icons)
cd ~/Library/Fonts && { curl -O 'https://github.com/Falkor/dotfiles/blob/master/fonts/SourceCodePro+Powerline+Awesome+Regular.ttf?raw=true' ; cd -; }

### install sack
git clone https://github.com/sampson-chen/sack.git && cd sack && chmod +x
install_sack.sh && ./install_sack.sh && cd .. && rm -fr sack

#############################################
### Installs from Mac App Store
#############################################

#echo "Installing apps from the App Store..."

### find app ids with: mas search "app name"
#brew install mas

### Mas login is currently broken on mojave. See:
### Login manually for now.

#cecho "Need to log in to App Store manually to install apps with mas...." $red
#echo "Opening App Store. Please login."
#open "/System/Applications/App Store.app"
#echo "Is app store login complete.(y/n)? "
#read response
#if [ "$response" != "${response#[Yy]}" ]
#then
#	mas install 907364780  # Tomato One - Pomodoro timer
#	# mas install 485812721  # Tweetdeck
#	mas install 668208984  # GIPHY Capture. The GIF Maker (For recording my screen as gif)
#	mas install 1351639930 # Gifski, convert videos to gifs
#	mas install 414030210  # Limechat, IRC app.
#else
#	cecho "App Store login not complete. Skipping installing App Store Apps" $red
#fi


#############################################
### Install few global python packages
#############################################

echo "Installing global Python packages..."

pip3 install --user --upgrade pip
pip3 install --user pylint
pip3 install --user flake8
pip3 install --user pipenv


#############################################
### Set OSX Preferences - Borrowed from https://github.com/mathiasbynens/dotfiles/blob/master/.macos
#############################################

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'


##################
### Finder, Dock, & Menu Items
##################

# Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Remove the auto-hiding Dock delay
defaults write com.apple.dock autohide-delay -float 0

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Only Show Open Applications In The Dock
defaults write com.apple.dock static-only -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Use list view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Minimize windows into their application’s icon
defaults write com.apple.dock minimize-to-application -bool true

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool false

# Don’t show recent applications in Dock
#    defaults write com.apple.dock show-recents -bool false

# Menu bar: hide the Time Machine, User icons, but show the volume Icon.
for domain in ~/Library/Preferences/ByHost/com.apple.systemuiserver.*; do
	defaults write "${domain}" dontAutoLoad -array \
		"/System/Library/CoreServices/Menu Extras/TimeMachine.menu" \
		"/System/Library/CoreServices/Menu Extras/User.menu"
done
defaults write com.apple.systemuiserver menuExtras -array \
	"/System/Library/CoreServices/Menu Extras/Volume.menu" \
	"/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
	"/System/Library/CoreServices/Menu Extras/AirPort.menu" \
	"/System/Library/CoreServices/Menu Extras/Battery.menu" \
	"/System/Library/CoreServices/Menu Extras/Clock.menu"

##################
### Text Editing / Keyboards
##################

# Disable smart quotes and smart dashes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Use function F1, F, etc keys as standard function keys
#defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true


###############################################################################
# Screenshots / Screen                                                        #
###############################################################################

# Require password immediately after sleep or screen saver begins"
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to the desktop
mkdir $HOME/Screenshots
defaults write com.apple.screencapture location -string "$HOME/Screenshots"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Address Book, Dashboard, iCal, TextEdit, and Disk Utility                   #
###############################################################################

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -int 0

###############################################################################
# Spotlight                                                                   #
###############################################################################

# Hide Spotlight tray-icon (and subsequent helper)
#sudo chmod 600 /System/Library/CoreServices/Search.bundle/Contents/MacOS/Search
# Disable Spotlight indexing for any volume that gets mounted and has not yet
# been indexed before.
# Use `sudo mdutil -i off "/Volumes/foo"` to stop indexing any volume.
sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes"
# Load new settings before rebuilding the index
killall mds

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

# Disable “natural” (Lion-style) scrolling
# Uncomment if you don't use scroll reverser
# defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Stop iTunes from responding to the keyboard media keys
#launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2> /dev/null

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Disable force click and haptic feedback
defaults write ~/Library/Preferences/com.apple.AppleMultitouchTrackpad.plist ForceSuppressed -bool true

# Mouse settings
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse.plist MouseOneFingerDoubleTapGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse.plist MouseTwoFingerDoubleTapGesture -int 3
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse.plist MouseTwoFingerHorizSwipeGesture -int 2
defaults write ~/Library/Preferences/.GlobalPreferences.plist com.apple.mouse.scaling -float 3
defaults write ~/Library/Preferences/.GlobalPreferences.plist com.apple.swipescrolldirection -boolean NO


###############################################################################
# Mac App Store                                                               #
###############################################################################

# Enable the automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install System data files & security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

###############################################################################
# Photos                                                                      #
###############################################################################

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Google Chrome                                                               #
###############################################################################

# Disable the all too sensitive backswipe on trackpads
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false


#############################################
### Install dotfiles repo, run link script
#############################################
# TODO:
# clean up my personal repo to make it public
# dotfiles for vs code, emacs, gitconfig, oh my zsh, etc.
git clone git@github.com:hopkinsju/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
#fetch submodules for oh-my-zsh
#git submodule init && git submodule update && git submodule status
# make symbolic links and change shell to zshell
bash scripts/bootstrap
upgrade_oh_my_zsh
mkdir -p "$HOME/.zsh"
git clone --depth=1 https://github.com/spaceship-prompt/spaceship-prompt.git "$HOME/.zsh/spaceship"


echo ""
cecho "Done!" $cyan
echo ""
echo ""
cecho "################################################################################" $white
echo ""
echo ""
cecho "Note that some of these changes require a logout/restart to take effect." $red
echo ""
echo ""
echo "Check for and install available OSX updates, install, and automatically restart? (y/n)?"
read response
if [ "$response" != "${response#[Yy]}" ] ;then
    softwareupdate -i -a --restart
fi
