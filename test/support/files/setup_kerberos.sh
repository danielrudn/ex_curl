#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive
export KERBEROS_USERNAME=admin
export KERBEROS_PASSWORD=secretpassword
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
    ${KERBEROS_REALM^^} = ${KERBEROS_REALM^^}

[logging]
    kdc = FILE:/var/log/krb5kdc.log
    admin_server = FILE:/var/log/kadmin.log
    default = FILE:/var/log/krb5lib.log
EOL

echo "*** Setup Kerberos ACL configuration at /etc/krb5kdc/kadm5.acl"
cat > /etc/krb5kdc/kdc.conf << EOL
[kdcdefaults]
    kdc_ports = 750,88

[realms]
    ${KERBEROS_REALM^^} = {
        database_name = /var/lib/krb5kdc/principal
        admin_keytab = FILE:/etc/krb5kdc/kadm5.keytab
        acl_file = /etc/krb5kdc/kadm5.acl
        key_stash_file = /etc/krb5kdc/stash
        kdc_ports = 750,88
        max_life = 10h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
        master_key_type = des3-hmac-sha1
        #supported_enctypes = aes256-cts:normal aes128-cts:normal
        default_principal_flags = +preauth
    }
EOL
echo -e "*/*@${KERBEROS_REALM^^}\t*" > /etc/krb5kdc/kadm5.acl

echo "*** Creating KDC database"
# krb5_newrealm returns non-0 return code as it is running in a container, ignore it for this command only
set +e
printf "$KERBEROS_PASSWORD\n$KERBEROS_PASSWORD" | krb5_newrealm
set -e

echo "*** Creating principals for tests"
kadmin.local -q "addprinc -pw $KERBEROS_PASSWORD $KERBEROS_USERNAME"

echo "*** Adding HTTP principal for Kerberos and create keytab"
kadmin.local -q "addprinc -randkey HTTP/localhost"
kadmin.local -q "ktadd -k /etc/krb5.keytab HTTP/localhost"
kadmin.local -q "addprinc -randkey HTTP/$KERBEROS_HOSTNAME"
kadmin.local -q "ktadd -k /etc/krb5.keytab HTTP/$KERBEROS_HOSTNAME"
chmod 777 /etc/krb5.keytab


echo "*** Restarting Kerberos KDS service"
service krb5-kdc restart

echo "*** Getting ticket for Kerberos user"
echo -n "$KERBEROS_PASSWORD" | kinit "$KERBEROS_USERNAME@${KERBEROS_REALM^^}"
