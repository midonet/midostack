
if [[ "$os_VENDOR" =~ (Red Hat) || "$os_VENDOR" =~ (CentOS) ]]; then
    sudo mkdir -p /usr/java/default/bin/
    sudo ln -s /usr/bin/java /usr/java/default/bin/java
elif [[ "$os_VENDOR" =~ (Ubuntu) || "$os_VENDOR" =~ (Debian) ]]; then
    # Maven installs Java 6; make sure we set Java 7 as primary
    # JDK so that MidoNet Maven build works
    sudo update-java-alternatives -s java-1.7.0-openjdk-amd64
fi
