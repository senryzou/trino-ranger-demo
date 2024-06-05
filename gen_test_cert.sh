#!/bin/bash 
set -e

#generated keystore/truststore
TLS_CERT_DIR="$(pwd)/tls"
KEYSTORE_PASSWORD=password




import_cert=false

pre_process_args()
{
    while [ $# -gt 0 ] ; do
      
      if [[ "$1" == --import ]]
      then
         import_cert=true
      fi

      shift
    done
}

genSelfSignedCert()
{

    echo "=== generating self signed cert in ${TLS_CERT_DIR} ==="
    rm -fr ${TLS_CERT_DIR}
    mkdir -p ${TLS_CERT_DIR}


svr_conf=$(cat << EOF
[req]
default_bits=2048
prompt=no
default_md=sha
distinguished_name=dn
req_extensions = v3_req

[dn]
C=YY
ST=XX
L=Home-Town
O=Data and AI
OU=For-CPD
emailAddress=dummy@example.dum
CN=Dummy-Self-signed-Cert

[v3_req]
subjectAltName = @alt_names
extendedKeyUsage = 1.3.6.1.5.5.7.3.1

[alt_names]
IP.1 = 127.0.0.1
DNS.1 = ibm-test-presto-svc
DNS.2 = *.svc.cluster.local
DNS.3 = api-svc
DNS.4 = *.api
DNS.5 = localhost
DNS.6 = ibm-test-hive-metastore
DNS.7 = ibm-test-hive-metastore-svc
DNS.8 = lhconsole-api-svc
DNS.9 = lhconsole-nodeclient-svc
DNS.10 = ibm-test-ranger-svc
DNS.11 = ibm-test-javaapi-svc
DNS.12 = ibm-test-prestissimo-svc
DNS.13 = ibm-test-qhmm
DNS.14 = ibm-test-qhmm-svc
DNS.15 = localhost-trino
DNS.16 = ranger-admin
DNS.17 = *.ibm.com


EOF
)

dns_counter=$(($(grep -c "DNS" <<< "${svr_conf}") + 1))

for host in "$@"; do
  svr_conf+="\nDNS.${dns_counter} = ${host}"
  dns_counter=$((dns_counter+1))
done 

echo -e "${svr_conf}" >  ${TLS_CERT_DIR}/server.csr.cnf

openssl req -x509 -passin pass:${KEYSTORE_PASSWORD} -sha512 -newkey rsa:2048 -keyout ${TLS_CERT_DIR}/cert.key -out ${TLS_CERT_DIR}/cert.crt -days 4096 -nodes -config ${TLS_CERT_DIR}/server.csr.cnf  -extensions v3_req



}

createJKS()
{
    openssl pkcs12 -export -passin pass:${KEYSTORE_PASSWORD} -passout pass:${KEYSTORE_PASSWORD} -in ${TLS_CERT_DIR}/cert.crt -inkey ${TLS_CERT_DIR}/cert.key -out ${TLS_CERT_DIR}/cert.p12 -name ibm-test-client -CAfile ${TLS_CERT_DIR}/cert.crt -caname root -chain

    keytool -importkeystore -alias ibm-test-client -destalias ibm-test-client -srckeystore ${TLS_CERT_DIR}/cert.p12 -srcstoretype pkcs12 -destkeystore ${TLS_CERT_DIR}/test-ssl-keystore.jks -noprompt -srckeypass ${KEYSTORE_PASSWORD} -destkeypass ${KEYSTORE_PASSWORD} -deststorepass ${KEYSTORE_PASSWORD} -srcstorepass ${KEYSTORE_PASSWORD}

    keytool -import -noprompt -alias ibm-test-client -trustcacerts -file ${TLS_CERT_DIR}/cert.crt -storepass ${KEYSTORE_PASSWORD} -keystore ${TLS_CERT_DIR}/test-ssl-truststore.jks -keypass ${KEYSTORE_PASSWORD}
}

### MAIN


if [ X"${TLS_CERT_DIR}" == X ];
then
  echo "missing required TLS_CERT_DIR environment variable"
  exit 1
fi

if [ X"${KEYSTORE_PASSWORD}" == X ];
then
  echo "missing required KEYSTORE_PASSWORD environment variable"
  exit 1
fi

pre_process_args "$@"


if [ "$import_cert" != true ] ; then
    genSelfSignedCert "$@"
fi
createJKS
