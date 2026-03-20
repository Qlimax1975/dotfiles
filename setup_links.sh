#!/bin/bash

# Directorul unde se află dotfiles (cale absolută)
DOTFILES_DIR=$(pwd)

# Lista de fișiere/foldere pentru care vrei symlink
# Adaugă aici orice fișier nou (ex: .bashrc, .zshrc, vremea.sh)
files=".bashrc .zshrc .gitconfig vremea.sh setup_links.sh"

echo "Inițiez crearea link-urilor simbolice..."

for file in $files; do
    # Ștergem fișierul vechi din home dacă există (sau backup)
    if [ -f ~/$file ] || [ -L ~/$file ]; then
        echo "Există deja $file în home. Îl șterg pentru a face loc link-ului."
        rm -rf ~/$file
    fi

    # Creăm link-ul simbolic
    echo "Creez link: ~/$file -> $DOTFILES_DIR/$file"
    ln -s $DOTFILES_DIR/$file ~/$file
done

echo "Gata! Toate link-urile au fost create."
