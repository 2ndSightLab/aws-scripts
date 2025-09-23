#!/bin/bash -e
# run this before installing Amazon Q"
echo "Only run this once! If you need to run it again first clear out the content it added to ~.bashrc"
echo ''  >> ~/.bashrc
echo '#remove docker color madness' >> ~/.bashrc
echo "export NO_COLOR=true" >> ~/.bashrc

echo ''  >> ~/.bashrc
echo '#set background color - change #c42e68 to change the color' >> ~/.bashrc
echo '#https://htmlcolorcodes.com/color-picker/' >> ~/.bashrc
echo '#this does not work on mac if you are using defulat zsh terminal app.' >> ~/.bashrc
echo '#should work in bash' >> ~/.bashrc
echo '#you can change to bash with this command:' >> ~/.bashrc
echo '#chsh -s /bin/bash' >> ~/.bashrc
echo '#Mac uses zsh due to licensing issues and it has some different features' >> ~/.bashrc
echo 'echo -e "\e]11;#c42e68\a"' >> ~/.bashrc
echo ''  >> ~/.bashrc
echo '#PS1'  >> ~/.bashrc
echo '#The first item is the prompt' >> ~/.bashrc
echo '#The terminal emulator looks for output containing that specific code (\e]0;) and uses everything up to the \a as the terminal window title.' >> ~/.bashrc
echo 'export PS1="(^: \e]0;2nd Sight Lab\a"' >> ~/.bashrc
echo ''  >> ~/.bashrc
echo "#white please..." >> ~/.bashrc
echo 'LS_COLORS="di=1;37:ex=1;37:fi=1;37:ln=1;37:pi=1;37:so=1;37:bd=1;37:cd=1;37:or=1;37:mi=1;37"' >> ~/.bashrc

echo ''  >> ~/.bashrc
echo "#But that is not working anymore so:" >> ~/.bashrc
echo "export NO_COLOR=1" >> ~/.bashrc
echo "alias ls='ls --color=never'" >> ~/.bashrc
echo "alias grep='grep --color=never'" >> ~/.bashrc
echo "alias diff='diff --color=never'" >> ~/.bashrc
echo "alias aws='aws --color off'" >> ~/.bashrc
echo "alias git='git -c color.ui=never'" >> ~/.bashrc
echo "#If you installed Amazon Q make sure that line is at the bottom of bashrc" >> ~/.bashrc

source ~/.bashrc
echo "all font should be white. If it is not trying executing source ~/.bashrc again."
