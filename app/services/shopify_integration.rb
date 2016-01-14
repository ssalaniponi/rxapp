class ShopifyIntegration
  SHOPIFY_API_KEY = "80bd0cb679a2cdc83ee622c24096b0b3"
  SHOPIFY_SHARED_SECRET = "1765d00e5fba3ad98e458395f6470f65"

  attr_accessor :url, :password, :account_id

  def initialize(params)
    # Ensure that all the parameters are passed in
    %w{url password account_id}.each do |field|
      raise ArgumentError.new("params[:#{field}] is required") if params[field.to_sym].blank?

      # If present, then set as an instance variable
      instance_variable_set("@#{field}", params[field.to_sym])
    end
  end

  # Uses the provided credentials to create an active Shopify session
  def connect

    # Initialize the gem
    ShopifyAPI::Session.setup({api_key: SHOPIFY_API_KEY, secret: SHOPIFY_SHARED_SECRET})

    # Instantiate the session
    session = ShopifyAPI::Session.new(@url, @password)

    # Activate the Session so that requests can be made
    return ShopifyAPI::Base.activate_session(session)

  end

  def update_account

    # This method grabs the ShopifyAPI::Shop information
    # and updates the local record

    shop = ShopifyAPI::Shop.current

    # Map the shop fields to our local model
    # Choosing clarity over cleverness
    account = Account.find @account_id

    account.shopify_shop_id = shop.id
    account.shopify_shop_name = shop.name
    account.shop_owner = shop.shop_owner
    account.email = shop.email

    account.save


  end

  def setup_webhooks

    webhook_url = "#{DOMAIN}/webhooks/uninstall"

    begin

      # Remove any existing webhooks
      webhooks = ShopifyAPI::Webhook.find :all
      webhooks.each do |webhook|
        webhook.destroy if webhook.address.include?(DOMAIN)
      end

      # Setup our webhook
      ShopifyAPI::Webhook.create(address: webhook_url, topic: "app/uninstalled", format: "json")

    rescue => ex
      puts "---------------"
      puts ex.message
    end

  end


  # This method is used to verify Shopify requests / redirects
  def self.verify(params)

    hash = params.slice(:code, :shop, :signature, :timestamp)

    received_signature = hash.delete(:signature)

    # Collect the URL parameters into an array of elements of the format "#{parameter_name}=#{parameter_value}"
    calculated_signature = hash.collect { |k, v| "#{k}=#{v}" } # => ["shop=some-shop.myshopify.com", "timestamp=1337178173", "code=a94a110d86d2452eb3e2af4cfb8a3828"]

    # Sort the key/value pairs in the array
    calculated_signature = calculated_signature.sort # => ["code=25e725143c2faf592f454f2949c8e4e2", "shop=some-shop.myshopify.com", "timestamp=1337178173

    # Join the array elements into a string
    calculated_signature = calculated_signature.join # => "code=a94a110d86d2452eb3e2af4cfb8a3828shop=some-shop.myshopify.comtimestamp=1337178173"

    # Final calculated_signature to compare against
    calculated_signature = Digest::MD5.hexdigest(SHOPIFY_SHARED_SECRET + calculated_signature) # => "25e725143c2faf592f454f2949c8e4e2"

    return calculated_signature == received_signature
  end

end