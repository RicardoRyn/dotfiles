########################################
####### manually inserted by RJX #######
########################################
eval "$(zoxide init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
alias vim='nvim'
alias vide='neovide'
alias y='yazi'
alias rjxssh='ssh ruanjx@192.168.22.171'
alias top='btop'
# auto-inserted by @update.afni.binaries :
export PATH=$PATH:/home/nhp/abin
# auto-inserted by @update.afni.binaries :
#    set up tab completion for AFNI programs
if [ -f $HOME/.afni/help/all_progs.COMP.zsh ]
then
   autoload -U +X bashcompinit && bashcompinit
   autoload -U +X compinit && compinit \
      && source $HOME/.afni/help/all_progs.COMP.zsh
fi
# fsl 配置
FSLDIR=~/fsl
PATH=${FSLDIR}/share/fsl/bin:${PATH}
export FSLDIR PATH
. ${FSLDIR}/etc/fslconf/fsl.sh
# freesurfer 配置
export FREESURFER_HOME=/usr/local/freesurfer/6.0.0
source $FREESURFER_HOME/SetUpFreeSurfer.sh
export PATH=$PATH:/usr/local/freesurfer/6.0.0
# conda 配置
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/nhp/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/nhp/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/nhp/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/nhp/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
# NHPPipelines 配置
export CARET7DIR=${HOME}/workbench/bin_linux64
export MSMBINDIR=${HOME}/fsl/bin
export HCPPIPEDIR=${HOME}/HCP_pipelines/NHPPipelines
export MSMCONFIGDIR=${HCPPIPEDIR}/MSMConfig
export HCPPIPEDIR_Templates=${HCPPIPEDIR}/global/templates
export HCPPIPEDIR_Bin=${HCPPIPEDIR}/global/binaries
export HCPPIPEDIR_Config=${HCPPIPEDIR}/global/config
export HCPPIPEDIR_PreFS=${HCPPIPEDIR}/PreFreeSurfer/scripts
export HCPPIPEDIR_FS=${HCPPIPEDIR}/FreeSurfer/scripts
export HCPPIPEDIR_PostFS=${HCPPIPEDIR}/PostFreeSurfer/scripts
export HCPPIPEDIR_fMRISurf=${HCPPIPEDIR}/fMRISurface/scripts
export HCPPIPEDIR_fMRIVol=${HCPPIPEDIR}/fMRIVolume/scripts
export HCPPIPEDIR_tfMRI=${HCPPIPEDIR}/tfMRI/scripts
export HCPPIPEDIR_dMRI=${HCPPIPEDIR}/DiffusionPreprocessing/scripts
export HCPPIPEDIR_dMRITract=${HCPPIPEDIR}/DiffusionTractography
export HCPPIPEDIR_Global=${HCPPIPEDIR}/global/scripts
export HCPPIPEDIR_tfMRIAnalysis=${HCPPIPEDIR}/TaskfMRIAnalysis/scripts
# rust配置
. "$HOME/.cargo/env"
# 添加PATH
export PATH=$PATH:/home/nhp/ricardo/nvim/nvim-linux-x86_64/bin
export PATH=$PATH:/home/nhp/workbench/bin_linux64
export PATH=$PATH:/home/nhp/ants/ants-2.5.4/bin
export PATH=$PATH:/home/nhp/ricardo/zotero/Zotero_linux-x86_64
export PATH=$PATH:/home/nhp/ricardo/7zip/7z2409-linux-x64
export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin
export PATH=$PATH:/home/nhp/python/Projects/gen_FC
export EDITOR=nvim
###########################################
####### 以上配置和.bashrc中基本相同 #######
###########################################
eval "$(starship init zsh)"
