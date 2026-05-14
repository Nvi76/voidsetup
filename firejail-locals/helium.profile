# Fix Input (Negate restrictions in chromium-common.profile)
ignore noinput
nodbus

# IBus Specific Access
ignore noroot
noblacklist ${RUNUSER}/ibus
writable-run-user

# Fix Networking (Negate netfilter in chromium-common.profile)
ignore netfilter

# Allow shared memory (Required for Electron/IBus rendering)
ignore noshm

# Whitelisted Folders
noblacklist ${HOME}/.config/Helium
whitelist ${HOME}/.config/Helium
whitelist ${HOME}/.config/net.imput.helium/Default/
whitelist ${HOME}/Downloads
whitelist ${HOME}/Pictures/AllowedPics
whitelist ${HOME}/Documents/AllowedDocs
whitelist ${HOME}/Projects/Allowed

# Redirect
include chromium-common.profile
