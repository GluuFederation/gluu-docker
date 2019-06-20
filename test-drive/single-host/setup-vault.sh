#!/bin/sh

set -e

init_vault() {
    vault_initialized=$(docker exec vault vault status -format=yaml | grep initialized | awk -F ': ' '{print $2}')

    if [ "${vault_initialized}" = "true" ]; then
        echo "[I] Vault already initialized"
    else
        echo "[W] Vault is not initialized; trying to initialize Vault with 1 recovery key and root token"
        docker exec vault vault operator init \
            -key-shares=1 \
            -key-threshold=1 \
            -recovery-shares=1 \
            -recovery-threshold=1 > $PWD/vault_key_token.txt
        echo "[I] Vault recovery key and root token saved to $PWD/vault_key_token.txt"
    fi
}

get_root_token() {
    if [ -f $PWD/vault_key_token.txt ]; then
        cat $PWD/vault_key_token.txt | grep "Initial Root Token" | awk -F ': ' '{print $2}'
    fi
}


enable_approle() {
    docker exec vault vault login -no-print $(get_root_token)

    approle_enabled=$(docker exec vault vault auth list | grep 'approle' || :)

    if [ -z "${approle_enabled}" ]; then
        echo "[W] AppRole is not enabled; trying to enable AppRole"
        docker exec vault vault auth enable approle
        docker exec vault vault write auth/approle/role/gluu policies=gluu
        docker exec vault \
            vault write auth/approle/role/gluu \
                secret_id_ttl=0 \
                token_num_uses=0 \
                token_ttl=20m \
                token_max_ttl=30m \
                secret_id_num_uses=0

        docker exec vault \
            vault read -field=role_id auth/approle/role/gluu/role-id > vault_role_id.txt

        docker exec vault \
            vault write -f -field=secret_id auth/approle/role/gluu/secret-id > vault_secret_id.txt
    else
        echo "[I] AppRole already enabled"
    fi
}

write_policy() {
    sleep 5
    docker exec vault vault login -no-print $(get_root_token)

    policy_created=$(docker exec vault vault policy list | grep gluu || :)

    if [ -z "${policy_created}" ]; then
        echo "[W] Gluu policy is not created; trying to create one"
        docker exec vault vault policy write gluu /vault/config/policy.hcl
    else
        echo "[I] Gluu policy already created"
    fi
}

get_unseal_key() {
    if [ -f $PWD/vault_key_token.txt ]; then
        cat $PWD/vault_key_token.txt | grep "Unseal Key 1" | awk -F ': ' '{print $2}'
    fi
}


unseal_vault() {
    sleep 5

    vault_sealed=$(docker exec vault vault status | grep 'Sealed' | awk -F ' ' '{print $2}' || :)
    if [ "${vault_sealed}" = "false" ]; then
        echo "[I] Vault already unsealed"
    else
        docker exec vault vault operator unseal $(get_unseal_key)
    fi
}

# init_vault
# unseal_vault
# write_policy
# enable_approle
