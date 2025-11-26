#
# ~/.zprofile
#

[[ -f ~/.zshrc ]] && . ~/.zshrc

. "$HOME/.local/bin/env"

# FSL Setup
FSLDIR=/home/ricardo/fsl
PATH=${FSLDIR}/share/fsl/bin:${PATH}
export FSLDIR PATH
. ${FSLDIR}/etc/fslconf/fsl.sh
