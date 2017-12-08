require 'chef/provider/lwrp_base'
require 'vault'

module VaultRetrieve
  class Helpers
    def self.vault_read(node, approle, path)
      # Only allow necessary approles, always allow chef and node application

      # Token to generate secret
      secret_generator = 'cd7a5bdc-222a-85c6-8f94-580ea2ee03da'

      # Instantiate vault
      vault = Vault::Client.new(address: "#{node['vault']['fqdn']}:#{node['vault']['port']}")

      # AppRole login
      vault.token = secret_generator
      secret_id = vault.approle.create_secret_id(approle).data.secret_id
      vault.auth.approle(approle, secret_id)

      # Secret retrieval
      secret = vault.logical.read(path)

      Chef::Log.warn(path)
      Chef::Log.warn(secret.data)

      # Return data
      secret.data
    end
  end
end
