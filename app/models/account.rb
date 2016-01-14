require Rails.root.join('spec', 'rails_helper.rb').to_s

class Account < ActiveRecord::Base
	validates_presence_of :shopify_account_url
	validates_presence_of :shopify_api_key
	validates_presence_of :shopify_password
	validates_presence_of :shopify_shared_secret

	# This should return the minimal set of attributes required
	# to create a valid Account. As you add validations to
	# Account, be sure to adjust the attributes here as well.

	RSpec.describe "valid attributes" do
		let(:valid_attributes) { { 
			"shopify_account_url" => "MyString", 
			"shopify_password" => "MyString",
			"shopify_api_key" => "MyString", 
			"shopify_shared_secret" => "MyString" 
		} }
	end
end