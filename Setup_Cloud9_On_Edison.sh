#!/bin/sh

WKS="/home/root/c9wks"  # Workspace path
USR_NAME=""         # Specify the user name here
PSWD=""           # Specify pass word here


function install_packages()
{
    opkg update
    opkg install git

    # Check if install of git went through

    if  [[ $? != 0 ]]; then
        echo "Please check the network and or the repos list"
        echo "If you have not configured the repos, refer to this link:"
        echo "http://alextgalileo.altervista.org/edison-package-repo-configuration-instructions.html"
        exit 1
    fi

    rm -r *.tar*
    set -e
    echo "Installing node"
    wget http://nodejs.org/dist/v0.12.0/node-v0.12.0.tar.gz
    tar zxvf node-v0.12.0.tar.gz
    cd node-v0.12.0
    ./configure
    # This is going to take good 3-5 hrs
    make
    make install
    cd ..
    
    # Install sinon
    npm install sinon

    # install mraa and upm
    npm install mraa
    npm install upm

    # Export the LD path where the libevent is installed for tmux to see
    # Temp fix, need to make this global; otherwise terminal realted features in c9 won't wotk  
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
    export LD_LIBRARY_PATH

    echo "Installing libevent"
    wget https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz
    tar -zxvf libevent-2.0.22-stable.tar.gz
    cd libevent-2.0.22-stable
    sh autogen.sh
    ./configure
    make
    make install
    cd ..


    echo "Installing tmux"
    git clone https://github.com/tmux/tmux.git
    cd tmux
    sh autogen.sh
    ./configure
    make
    make install
    cd ..

    # Get to the main package now
    echo "Installing Cloud 9 IDE"
    git clone git://github.com/c9/core.git c9sdk
    cd c9sdk
    ./scripts/install-sdk.sh
    cd ..

    if [ ! -d $WKS ];then
        mkdir $WKS
    fi
    
    echo "Installing pylint "
    wget http://peak.telecommunity.com/dist/ez_setup.py
    python ez_setup.py
    easy_install pylint

    read -p "Do you want to replace the stock 'ps' on Edison with an version that is required by Cloud 9 IDE (y/n)?" resp
    
    case $resp in
        [Nn]* ) return ;;
    esac 
    
    opkg install kernel-dev
    
    echo "Insatlling the procps"
    
    git clone https://github.com/navin-bhaskar/procps.git
    cd procps   
    make
    make install_ps
    
}

function start()
{
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
    export LD_LIBRARY_PATH
    if [ -d "c9sdk" ];then
        cd c9sdk
        # Start the server
        ./server.js -p 8080 -l 0.0.0.0 -a $USR_NAME:$PSWD -w $WKS
    else
        echo "Please run this script with install option first"
    fi
}


if [[ $# -eq 1 ]]; then
    if [ $1 = "install" ]; then
        echo "Installing the required packages and Cloud 9 IDE "
        install_packages
    fi
else
    start
fi


