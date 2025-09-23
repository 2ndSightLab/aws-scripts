#!/bin/bash -e

sudo su ec2-user
THIS_DIR=$(pwd)
cd /home/ec2-user

OUTPUT_FILE="tr.vim"
if [ ! -d ~/.vim ]; then mkdir ~/.vim; fi
if [ ! -d ~/.vim/colors ]; then mkdir ~/.vim/colors; fi
if [ ! -f ~/.vim/colors/$OUTPUT_FILE ]; then touch ~/.vim/colors/$OUTPUT_FILE; fi
cd ~/.vim/colors

cat > "$OUTPUT_FILE" << 'EOF'
" Howto: https://medium.com/cloud-security/changing-vim-colors-and-risks-in-vim-colors-files-from-the-internet-b0276a0fc38e
" Groupnames: https://vimdoc.sourceforge.net/htmldoc/syntax.html#group-name
hi Normal ctermfg=White
hi Comment ctermfg=LightGrey
hi Constant ctermfg=White
hi String ctermfg=White
hi Character ctermfg=White
hi Number ctermfg=White
hi Boolean ctermfg=White
hi Identifier ctermfg=White
hi Function ctermfg=White
hi Statement ctermfg=White
hi Conditional ctermfg=White
hi Repeat ctermfg=White
hi Label ctermfg=White
hi Operator ctermfg=White
hi Keyword ctermfg=White
hi Exception ctermfg=White
hi Preproc ctermfg=White
hi Include ctermfg=White
hi Define ctermfg=White
hi Macro ctermfg=White
hi PreCondit ctermfg=White
hi Type ctermfg=White
hi StorageClass ctermfg=White
hi Structure ctermfg=White
hi Typedef ctermfg=White
hi Special ctermfg=White
hi SpecialChar ctermfg=White
hi Tag ctermfg=White
hi Delimiter ctermfg=White
hi SpecialComment ctermfg=White
hi Debug ctermfg=White
hi Underlined ctermfg=White
hi Ignore ctermfg=White
hi Error ctermfg=Yellow
hi ToDo ctermfg=LightGrey
EOF

cd /home/ec2-user
echo 'colo tr' > ~/.vimrc

sudo su

cd $THIS_DIR

