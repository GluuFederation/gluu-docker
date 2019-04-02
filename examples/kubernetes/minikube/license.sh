#!/bin/sh

set -e

check_license() {
    # read from configmaps
    license_ack=$(kubectl get cm gluu-license -o jsonpath='{.data.license_ack}')

    if [ $license_ack != "true" ]; then
        echo "Gluu License Agreement: https://github.com/GluuFederation/gluu-docker/blob/3.1.4/LICENSE"
        echo ""
        read -p "Do you acknowledge that use of Gluu Server Docker Edition is subject to the Gluu Support License [y/N]: " ACCEPT_LICENSE

        case $ACCEPT_LICENSE in
            y|Y)
                ACCEPT_LICENSE="true"
                kubectl create cm gluu-license --from-literal=license_ack=$ACCEPT_LICENSE
                ;;
            n|N|"")
                ACCEPT_LICENSE="false"
                exit 1
                ;;
            *)
                echo "Error: invalid input"
                exit 1
        esac
    fi
}

# ==========
# entrypoint
# ==========
check_license
