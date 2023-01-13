#!/bin/bash

oldIFS=$IFS # On stocke la valeur initiale de l'IFS
IFS=$'\n'   # On modifie la valeur de l'IFS pour utiliser plutôt le retour à la ligne
maxdepth=0  # On initalise la variable $maxdepth à 0 (ce qui indique qu'il n'y a aucune limite)
dirFound=false  # On initialise la variable booléene $dirFound à false pour savoir si un répertoire à bien été donné en paramètre
printSize=false # On initialise la variable booléene $printSize à false car par défaut on n'affiche pas la taille des éléments
dir=""  # On initialise la variable $dir à chaîne vide, ce qui nous servira par la suite à stocker le répertoire donnée en paramètre

function exitWithError() {  # Arrête le programme et permet d'afficher un message passé en paramètre ($1)
    if [[ -n $1 ]]  # Si un paramètre à été donné
    then 
        echo -ne "\nError: $1\n"    #On affiche un message d'erreur
    fi
    IFS=$oldIFS # On remet toujours IFS à sa valeur initiale avant l'arrêt du programme
    exit 1  # On met fin au programme avec le code 1 pour indiquer qu'une erreur est survenue
}

function listSubElements() {    # Affiche les éléments contenu dans le répertoire passé en paramètre ($1) en fonction d'une profondeur donnée ($2)
    if [ $maxdepth -eq 0 -o $2 -lt $maxdepth ]  # Si on excède pas  la profondeur renseignée en paramètre
    then
        if [[ -d $1 ]]  # Si le paramètre 1 et un répertoire
        then
            local files=$(find $1 -mindepth 1 -maxdepth 1)  # On stock dans la variable $files les élèments contenus dans le répertoire
            for file in $files  # Pour chaque éléments de la variable $files
            do
                for i in $(seq 1 $2)    # On effectue un nombre de tabulation égale à la profondeur donnée en paramètre
                do
                    echo -ne "    "
                done
                local fileName=$(basename $file)    # On récupère le nom de l'élément
                if [[ printSize ]]  # Si l'option --size à été utilisé
                then
                    dirsize $file   # On appelle la fonction dirsize avec $file en paramètre pour récupérer sa taille dans la variable $size
                    echo -ne "|-- $fileName ($size)\n"  # On affiche le nom de l'élément ainsi que sa taille
                else
                    echo -ne "|-- $fileName\n"  # Sinon on affiche simplement le nom de l'élément
                fi
                if [[ -d $file ]]   # Si l'élément est un répertoire
                then
                    listSubElements $file $(($2 + 1))   # On appelle de nouveau cette fonction, en incrémentant la profondeur de 1
                fi
            done
        else
            exitWithError "A folder found by the \'find\' command is incorrect."
        fi
    fi
}

function mytree() {     # Prend un répertoire en paramètre et affiche les répertoires qu'il contient sous forme d'un arbre
    if [[ -d $1 ]]      # Si le paramètre est un répertoire
    then
        if [[ $(find $1 | wc -l) = 0 ]]     # Si le répertoire est vide
        then 
            exitWithError "The following folder is empty : $1."
        else
            if [[ printSize ]]  # Si l'option --size à été utilisé
            then
                dirsize $1  # On appelle la fonction dirsize avec $file en paramètre pour récupérer sa taille dans la variable $size
                echo -ne "$1 ($size)\n" # On affiche le nom de l'élément ainsi que sa taille
            else
                echo -ne "$1\n" # Sinon on affiche simplement le nom de l'élément
            fi
            listSubElements $1 0    # On appelle la fonction listSubElements sur le répertoire avec une profondeur initiale de 0
        fi
    else 
        exitWithError "The folder given in parameters is incorrect."
    fi
}

function dirsize() {    # Récupère la taille de l'élément passé en paramètre ($1) et la stocke dans la variable $size
    if [ -d $1 -o -f $1 ]   # Si l'élément est un répertoire ou un fichier
    then
        size=$(du $1 -hs | cut -f1) # On récupère la taille à l'aide des commandes 'du' et 'cut'
    else
        exitWithError "A folder found by the \'found\' command is incorrect."
    fi
}

while [[ -n "$1" ]]     # On boucle sur tous les paramètres      
do
    case "$1" in        # On utilise un switch sur le paramètre courant pour réaliser une action en fonction de celui-ci
        --max-depth)    # Dans le cas de --max-depth
            shift       # On utilise le shift pour passé à l'argument suivant
            if [[ "$1" -gt 0 ]] # Si l'argument suivant est un entier supérieur à 0
            then
                maxdepth=$1 # On peut stocker sa valeur dans la variable $maxdepth
            else
                exitWithError "The --max-depth value must be a positive integer (greater than 0)."
            fi
        ;;
        --size) # Dans le cas de --size
            printSize=true  # On change la valeur du booléen printSize à true
        ;;
        --help) # Dans le cas de --help
            echo -ne "\nUsage : dutree.sh [--max-depth N] [--help] [directory]\n" # On affiche l'aide
            IFS=$oldIFS # On remet toujours IFS à sa valeur initiale avant l'arrêt du programme
            exit 0  # On met fin au programme avec la valeur 0 pour indiquer que tout c'est passé comme prévu
        ;;
        *)  # Dans tous les autre cas
            if [[ -d $1 ]]  # Si le paramètre est un répertoire
            then
                if [[ !$dirFound ]] # Si on a pas déjà traiter un répertoire auparavant
                then
                    dir=$1  # On stocke ce répertoire dans la variable $dir
                    dirFound=true   # On change la valeur de la variable booléenne dirFound à true pour indiquer qu'on a bien traiter un répertoire
                else
                    exitWithError "Too many directories were given in parameters. Only 1 directory can be processed at a time."
                fi
            else
                exitWithError "unsupported option: --bad-opt"
            fi
        ;;
    esac
    shift # On passe à l'argument suivant
done
if [ $dirFound ]
then 
    mytree $dir # On appelle la fonction mytree avec le répertoire en paramètre
else
    exitWithError "No directory was given in parameters."
fi
IFS=$oldIFS
exit 0
