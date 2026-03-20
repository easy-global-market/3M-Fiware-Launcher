# !/bin/sh

export NIFI_INSTANCE_KEY=egm
export CLIENT_NAME=EGM
# Generate passwords using openssl rand -base64 ${1:-33}
export KEYSTORE_PASSWORD=keystorePassword
export TRUSTSTORE_PASSWORD=truststorePassword
export CLIENT_DOMAIN_NAME=localhost
export VM_IP=127.0.0.1

# Define certificate parameters
CN="nifi-$NIFI_INSTANCE_KEY"
OU="NIFI"
O=$CLIENT_NAME
DAYS_VALID=1825

mkdir -p certs

# Generate private key
openssl genpkey -algorithm RSA -out certs/nifi.key -aes256 -pass pass:"$KEYSTORE_PASSWORD"

# Generate Certificate Signing Request (CSR)
openssl req -new -key certs/nifi.key -out certs/nifi.csr -passin pass:"$KEYSTORE_PASSWORD" \
  -subj "/CN=$CN/O=$O/OU=$OU" -addext "subjectAltName=IP:$VM_IP" 

# Generate self-signed certificate
openssl x509 -req -days $DAYS_VALID -in certs/nifi.csr -signkey certs/nifi.key -out certs/nifi.crt \
  -passin pass:"$KEYSTORE_PASSWORD"

# Convert to PKCS12 keystore
openssl pkcs12 -export -in certs/nifi.crt -inkey certs/nifi.key -out certs/keystore.p12 \
  -name "nifi-$NIFI_INSTANCE_KEY" -passin pass:"$KEYSTORE_PASSWORD" -passout pass:"$KEYSTORE_PASSWORD"

# Create a truststore and add the certificate
keytool -storetype PKCS12 -importcert -file certs/nifi.crt -alias "nifi-$NIFI_INSTANCE_KEY" -keystore certs/truststore.p12 \
  -storepass "$TRUSTSTORE_PASSWORD" -noprompt
