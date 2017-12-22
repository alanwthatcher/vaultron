require 'vault'

resource_name :vault_token
provides :vault_token

property :destination, String, name_property: true
property :address, String
property :token, String # Token to create token, usually parent of created token
property :approle, String
property :id, String # can only be used by root token for create, used to identify for other actions
property :policies, Array
property :meta, Hash
property :no_parent, [true, false], default: false # don't do it, bad practice usually
property :no_default_policy, [true, false], default: false
property :renewable, [true, false], default: true
property :ttl, String
property :explicit_max_ttl, String
property :display_name, String
property :num_uses, Integer, default: 0
property :period, String

action :create do
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

  # Cobble options together if they are passed
  options = {
    id: (new_resource.id if property_is_set?(:id)),
    policies: (new_resource.policies if property_is_set?(:policies)),
    meta: (new_resource.meta if property_is_set?(:meta)),
    no_parent: (new_resource.meta if new_resource.meta),
    no_default_policy: (new_resource.no_default_policy if new_resource.no_default_policy),
    renewable: (new_resource.renewable unless new_resource.renewable),
    ttl: (new_resource.ttl if property_is_set?(:ttl)),
    explicit_max_ttl: (new_resource.explicit_max_ttl if property_is_set?(:explicit_max_ttl)),
    display_name: (new_resource.display_name if property_is_set?(:display_name)),
    num_uses: (new_resource.num_uses if new_resource.num_uses > 0),
    period: (new_resource.period if property_is_set?(:period))
  }.reject{ |k,v| v.nil? }


  # Create token
  token_create = Vault.auth_token.create(options)

  # Assign token data to destination
  node.run_state[new_resource.destination] = token_create.auth

  # Fire notification
  updated_by_last_action(true)
end

action :revoke do
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

  # Revoke the token
  Vault.auth_token.revoke(new_resource.id)

  # Fire notifications
  updated_by_last_action(true)
end
