# !/bin/bash

# Launch it using bash ./generate_certificate.sh (not zsh compliant)

export CLIENT_NAME=SaaS
export NIFI_INSTANCE_KEY=saas-production
# Generate passwords using openssl rand -base64 ${1:-33}
export KEYSTORE_PASSWORD=Rcushpvu91vqKw8xbXas1e2qTG8jJhYFP9eN3xu082Bn
export TRUSTSTORE_PASSWORD=PRzpiXXzOKCvPxom7xqr4Itm6IVG/Dq5TAp9txT+rA9q
export VM_IP=151.80.59.180

export OUTPUT_DIR=certs_${CLIENT_NAME}_${NIFI_INSTANCE_KEY}
CN="nifi-$NIFI_INSTANCE_KEY"
OU="NIFI"
O=$CLIENT_NAME
DAYS_VALID=1825

mkdir -p $OUTPUT_DIR

# Generate private key
openssl genpkey -algorithm RSA -out $OUTPUT_DIR/nifi.key -aes256 -pass pass:"$KEYSTORE_PASSWORD"

# Generate Certificate Signing Request (CSR)
openssl req -new -key $OUTPUT_DIR/nifi.key -out $OUTPUT_DIR/nifi.csr -passin pass:"$KEYSTORE_PASSWORD" \
  -subj "/CN=$CN/O=$O/OU=$OU" -addext "subjectAltName=IP:$VM_IP,DNS:localhost"

# Generate self-signed certificate
openssl x509 -req -days $DAYS_VALID -in $OUTPUT_DIR/nifi.csr -signkey $OUTPUT_DIR/nifi.key -out $OUTPUT_DIR/nifi.crt \
  -passin pass:"$KEYSTORE_PASSWORD" -extensions SAN \
  -extfile <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=IP:$VM_IP,DNS:localhost"))

# Convert to PKCS12 keystore
openssl pkcs12 -export -in $OUTPUT_DIR/nifi.crt -inkey $OUTPUT_DIR/nifi.key -out $OUTPUT_DIR/keystore.p12 \
  -name "nifi-$NIFI_INSTANCE_KEY" -passin pass:"$KEYSTORE_PASSWORD" -passout pass:"$KEYSTORE_PASSWORD"

# Create a truststore and add the certificate
keytool -storetype PKCS12 -importcert -file $OUTPUT_DIR/nifi.crt -alias "nifi-$NIFI_INSTANCE_KEY" -keystore $OUTPUT_DIR/truststore.p12 \
  -storepass "$TRUSTSTORE_PASSWORD" -noprompt

# Once created, you may use one of these commands to import the certificates in each others truststore

# Import registry cert in prod truststore
# keytool -importcert -noprompt -alias nifi-registry -file ./certs_registry/nifi.crt -keystore certs_prod/truststore.p12 -storepass truststorePassword -storetype PKCS12 -v

# Import prod cert in registry truststore
# keytool -importcert -noprompt -alias nifi-prod -file ./certs_prod/nifi.crt -keystore certs_registry/truststore.p12 -storepass truststorePassword -storetype PKCS12 -v

# Import registry cert in recette truststore
# keytool -importcert -noprompt -alias nifi-registry -file ./certs_registry/nifi.crt -keystore certs_recette/truststore.p12 -storepass truststorePassword -storetype PKCS12 -v

# Import recette cert in registry truststore
# keytool -importcert -noprompt -alias nifi-recette -file ./certs_recette/nifi.crt -keystore certs_registry/truststore.p12 -storepass truststorePassword -storetype PKCS12 -v
