#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive
export KERBEROS_HOSTNAME=$(cat /etc/hostname)
export KERBEROS_REALM=$(echo "$KERBEROS_HOSTNAME" | cut -d'.' -f2,3)

echo "*** Creating Kerberos config file at /etc/krb5.conf"
cat > /etc/krb5.conf << EOL
[libdefaults]
    default_realm = ${KERBEROS_REALM^^}
    dns_lookup_realm = false
    dns_lookup_kdc = false

[realms]
    ${KERBEROS_REALM^^} = {
        kdc = localhost
        admin_server = localhost
    }

[domain_realm]
    .$KERBEROS_REALM = ${KERBEROS_REALM^^}

[logging]
    kdc = FILE:/var/log/krb5kdc.log
    admin_server = FILE:/var/log/kadmin.log
    default = FILE:/var/log/krb5lib.log
EOL

echo "*** Setup Kerberos ACL configuration at /etc/krb5kdc/kadm5.acl"
echo -e "*/*@${KERBEROS_REALM^^}\t*" > /etc/krb5kdc/kadm5.acl


echo "*** Creating KDC database"
# krb5_newrealm returns non-0 return code as it is running in a container, ignore it for this command only
set +e
printf "$KERBEROS_PASSWORD\n$KERBEROS_PASSWORD" | krb5_newrealm
set -e

echo "*** Creating principals for tests"
kdb5_util create -r "$KERBEROS_REALM" -s -P "$KERBEROS_PASSWORD"
kadmin.local -q "addprinc -pw $KERBEROS_PASSWORD $KERBEROS_USERNAME"

echo "*** Adding HTTP principal for Kerberos and create keytab"
kadmin.local -q "addprinc -randkey HTTP/$KERBEROS_HOSTNAME"
kadmin.local -q "ktadd -k /etc/krb5.keytab HTTP/$KERBEROS_HOSTNAME"
chmod 777 /etc/krb5.keytab


echo "*** Restarting Kerberos KDS service"
service krb5-kdc restart

echo "*** Getting ticket for Kerberos user"
echo -n "$KERBEROS_PASSWORD" | kinit "$KERBEROS_USERNAME@${KERBEROS_REALM^^}"
