
if [ ! -f $HOME/.config/R/.Renviron ] ; then
    cat /etc/R/.Renviron | envsubst > $HOME/.config/R/.Renviron
fi
