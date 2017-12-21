require 'vault'

resource_name :vault
provides :vault

property :path, String, name_property: true
property :destination, String
property :address, String
property :approle, String
property :token, String
property :payload, Hash
property :data_only, [true, false], default: true

action :read do
  # run_state destination defaults to path
  new_resource.destination ||= new_resource.path

  # use Vault singleton
  Vault.address = new_resource.address

  # Auth with token provided
  Vault.token = new_resource.token

  # If approle is passed, use approle login
  if property_is_set?(:approle)
    # Lookup role-id
    approle_id = Vault.approle.role_id(new_resource.approle)

    # Generate a secret-id
    secret_id = Vault.approle.create_secret_id(new_resource.approle).data[:secret_id]

    # Login with approle auth provider
    Vault.auth.approle(approle_id, secret_id)
  end

  # Secret retrieval
  secret = Vault.logical.read(new_resource.path)

  # Asign secret to destination
  node.run_state[new_resource.destination] = new_resource.data_only ? secret.data : secret

  # Fire notification
  updated_by_last_action(true)
end

action :read_multi do
  # run_state destination beginning path
  new_resource.destination ||= new_resource.path

  # aggregate secrets for appending to destination
  secrets = Mash.new

  # use Vault singleton
  Vault.address = new_resource.address

  # Auth with token provided
  Vault.token = new_resource.token

  # If approle is passed, use approle login
  if property_is_set?(:approle)
    # Lookup role-id
    approle_id = Vault.approle.role_id(new_resource.approle)

    # Generate a secret-id
    secret_id = Vault.approle.create_secret_id(new_resource.approle).data[:secret_id]

    # Login with approle auth provider
    Vault.auth.approle(approle_id, secret_id)
  end

  # List and read each path, excluding sub-paths
  Vault.logical.list(new_resource.path).each do |s|
    next if s.end_with?('/')
    secret = Vault.logical.read("#{destination}/#{s}")
    secrets[s] = data_only ? secret.data : secret
  end

  # Append all read secrets to destination
  node.run_state[new_resource.destination] = secrets

  # Fire notifications
  updated_by_last_action(true)
end

action :transit_decrypt do
  # Instantiate vault
  Vault.address = new_resource.address

  # Use provided token
  Vault.token = new_resource.token

  # Return decrypted base64 string
  decrypted = Vault.logical.write(new_resource.path, new_resource.payload)

  # Assign decoded value to destination
  node.run_state[new_resource.destination] = Base64.decode64(decrypted.data[:plaintext])

  # Fire notification
  updated_by_last_action(true)
end

action :write do
  # run_state path defaults to destination
  new_resource.path ||= new_resource.destination

  # use Vault singleton
  Vault.address = new_resource.address

  # Auth with token provided
  Vault.token = new_resource.token

  # If approle is passed, use approle login
  if property_is_set?(:approle)
    # Lookup role-id
    approle_id = Vault.approle.role_id(new_resource.approle)

    # Generate a secret-id
    secret_id = Vault.approle.create_secret_id(new_resource.approle).data[:secret_id]

    # Login with approle auth provider
    Vault.auth.approle(approle_id, secret_id)
  end

  # Write to Vault
  Vault.logical.write(new_resource.path, new_resource.payload)

  # Fire notification
  updated_by_last_action(true)
end
