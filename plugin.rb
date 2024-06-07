# frozen_string_literal: true

# name: hash-plugin
# about: Hash Plugin
# meta_topic_id: 9999
# version: 0.0.1
# authors: Discourse
# url: https://github.com/Nilay1004/hash-plugin.git
# required_version: 2.7.0

enabled_site_setting :plugin_name_enabled

after_initialize do
  Rails.logger.info "PIIEncryption: Plugin initialized"
  
  require_dependency 'user'

  module ::PIIEncryption
    class << self
      def hash_email(email)
        return email if email.nil? || email.empty?

        uri = URI.parse("http://35.174.88.137:8080/hash")  # Replace with your actual hashing API endpoint
        http = Net::HTTP.new(uri.host, uri.port)

        request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
        request.body = { data: email, pii_type: "email" }.to_json
        response = http.request(request)

        JSON.parse(response.body)["hashed_data"]
      rescue StandardError => e
        Rails.logger.error "Error hashing email: #{e.message}"
        email
      end

      def encrypt_email(email)
        return email if email.nil? || email.empty?

        uri = URI.parse("http://35.174.88.137:8080/encrypt")
        http = Net::HTTP.new(uri.host, uri.port)

        request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
        request.body = { data: email, pii_type: "email" }.to_json
        response = http.request(request)

        JSON.parse(response.body)["encrypted_data"]
      rescue StandardError => e
        Rails.logger.error "Error encrypting email: #{e.message}"
        email
      end

      def decrypt_email(encrypted_email)
        return encrypted_email if encrypted_email.nil? || encrypted_email.empty?

        uri = URI.parse("http://35.174.88.137:8080/decrypt")
        http = Net::HTTP.new(uri.host, uri.port)

        request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
        request.body = { data: encrypted_email, pii_data: "email" }.to_json
        response = http.request(request)

        JSON.parse(response.body)["decrypted_data"]
      rescue StandardError => e
        Rails.logger.error "Error decrypting email: #{e.message}"
        encrypted_email
      end
    end
  end

  class ::User
    before_save :encrypt_and_hash_email

    private

    def encrypt_and_hash_email
      if email_changed?
        write_attribute(:email, PIIEncryption.encrypt_email(email))
        write_attribute(:email_hash, PIIEncryption.hash_email(email))
      end
    end

    def self.exists_with_hashed_email?(email)
      email_hash = PIIEncryption.hash_email(email)
      exists?(email_hash: email_hash)
    end
  end

  # Ensure we do not decrypt the email during validation
  module ::PIIEncryption::UserPatch
    def email
      if new_record?
        # Return the raw email attribute during the signup process
        read_attribute(:email)
      else
        super
      end
    end
  end

  ::User.prepend(::PIIEncryption::UserPatch)
end
