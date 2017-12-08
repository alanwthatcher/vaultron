require 'vault'

resource_name :vault_retrieve
provides :vault_retrieve

property :path, String, name_property: true
property :destination, String
property :address, String, default: "#{node['vault']['fqdn']}:#{node['vault']['port']}"
property :approle, String, equal_to: [ 'chef' ], default: 'chef'

action :single_read do
  # run_state destination defaults to path
  destination ||= path

  secret_generator = 'cd7a5bdc-222a-85c6-8f94-580ea2ee03da'

  # Instantiate vault
  vault = Vault::Client.new(address: address)

  # AppRole login
  vault.token = secret_generator
  secret_id = vault.approle.create_secret_id(approle).data[:secret_id]
  vault.auth.approle(approle, secret_id)

  # Secret retrieval
  secret = vault.logical.read(path)

  # Retrieve data
  node.run_state[destination] = secret.data
end
