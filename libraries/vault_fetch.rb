require 'chef/provider/lwrp_base'
require 'vault'

module Vaultron
  class Helpers
    def self.transit_decode(address, token, path, payload)
      # Vault singleton
      Vault.address = address

      # Auth with provided token
      Vault.token = token

      # Decrypt
      decrypted = Vault.logical.write(path, ciphertext: payload)

      # Return decoded string
      Base64.decode64(decrypted.data[:plaintext])
    end

    def self.read(address, token, path, approle = nil, data_only = true)
      # Vault singleton
      Vault.address = address

      # Auth with given token
      Vault.token = token

      # If approle is passed, use approle login
      unless approle.nil?
        # Lookup role-id
        approle_id = Vault.approle.role_id(approle)

        # Generate a secret-id
        secret_id = Vault.approle.create_secret_id(approle).data[:secret_id]

        # Login with approle auth provider
        Vault.auth.approle(approle_id, secret_id)
      end

      # Retrieve and return secret
      secret = Vault.logical.read(path)
      if data_only
        secret.data
      else
        secret
      end
    end

    def self.read_multi(address, token, path, approle = nil, data_only = true)
      # holder for multiple secrets
      secrets = Mash.new

      # use Vault singleton
      Vault.address = address

      # Auth with token provided
      Vault.token = token

      # If approle is passed, use approle login
      unless approle.nil?
        # Lookup role-id
        approle_id = Vault.approle.role_id(approle)

        # Generate a secret-id
        secret_id = Vault.approle.create_secret_id(approle).data[:secret_id]

        # Login with approle auth provider
        Vault.auth.approle(approle_id, secret_id)
      end

      # List and read each path, excluding sub-paths
      Vault.logical.list(path).each do |s|
        next if s.end_with?('/')
        secret = Vault.logical.read("#{path}/#{s}")
        secrets[s] = data_only ? secret.data : secret
      end

      # Return secrets
      secrets
    end

    def self.write(address, token, path, payload, approle = nil)
      # Vault singleton
      Vault.address = address

      # Auth with given token
      Vault.token = token

      # If approle is passed, use approle login
      unless approle.nil?
        # Lookup role-id
        approle_id = Vault.approle.role_id(approle)

        # Generate a secret-id
        secret_id = Vault.approle.create_secret_id(approle).data[:secret_id]

        # Login with approle auth provider
        Vault.auth.approle(approle_id, secret_id)
      end

      # Write secret, return result
       Vault.logical.write(path, payload)
    end
  end
end
