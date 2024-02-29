require "json"
require "httparty"

class GoogleDriveCredentials
  include HTTParty
  #
  CREDENTIALS_PATH = Rails.root.join("credentials.json")
  CLIENT_ID = ENV["CLIENT_ID"]
  CLIENT_SECRET = ENV["CLIENT_SECRET"]
  #set base_uri as a class method
  base_uri "https://oauth2.googleapis.com"

  def read_credentials
    begin
      file_content = File.read(CREDENTIALS_PATH)
      credentials = JSON.parse(file_content)

      return credentials
    rescue => err
      raise "Error reading credentials from file #{err.message}"
    end
  end

  def check_token_expiration(expiration_time = Time.now.to_i)
    current_timestamp = Time.now.to_i #get current time and convert it to unix time
    return current_timestamp > expiration_time #make sure the current time is greater than the expiration time
  end

  def get_new_credentials(refresh_token)
    token_endpoint = "/token"

    begin
      response = self.class.post(token_endpoint, {
        body: {
          grant_type: "refresh_token",
          client_id: CLIENT_ID,
          client_secret: CLIENT_SECRET,
          refresh_token: refresh_token,
        },
      })

      if response.success?
        data = response.parsed_response
        return data
      else
        raise "Error refreshing access token: #{response.body}"
      end
    rescue => error
      raise "Error refreshing access token: #{error.message}"
    end
  end

  def update_credentials
    begin
      credentials = read_credentials
      is_expired = check_token_expiration(credentials["expires_in"])

      if is_expired
        new_creds = get_new_credentials(credentials["refresh_token"])

        if new_creds
          credentials["access_token"] = new_creds["access_token"]
          credentials["expires_in"] = Time.now.to_i + new_creds["expires_in"]
        end
      end

      return credentials
    rescue => error
      raise "Error updating credentials #{error.message}"
    end
  end

  def save_credentials(json_data)
    begin
      File.write(CREDENTIALS_PATH, json_data, mode: "w:utf-8")
    rescue => err
      raise "Error writing credentials to file: #{err.message}"
    end
  end
end
