require "httparty"

class Drive::Oauth::GoogleController < ApplicationController
  include HTTParty
  base_uri "https://oauth2.googleapis.com"
  #
  CLIENT_ID = ENV["CLIENT_ID"]
  CLIENT_SECRET = ENV["CLIENT_SECRET"]
  REDIRECT_URI = ENV["REDIRECT_URI"]

  def get
    code = params[:code]

    begin
      values = {
        code: code,
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        redirect_uri: REDIRECT_URI,
        grant_type: "authorization_code",
      }

      response = self.class.post("/token", body: values)

      data = response.parsed_response
      access_token = data["access_token"]
      id_token = data["id_token"]
      refresh_token = data["refresh_token"]
      expires_in = data["expires_in"]

      credentials_json = {
        access_token: access_token,
        id_token: id_token,
        refresh_token: refresh_token,
        expires_in: Time.now.to_i + expires_in,
      }.to_json

      credentials_instance = GoogleDriveCredentials.new
      credentials_instance.save_credentials(credentials_json)

      csrf_cookie_value = form_authenticity_token

      response.headers["X-CSRF-Token"] = csrf_cookie_value

      redirect_to "http://localhost:5173"
    rescue HTTParty::Error, StandardError => e
      puts "Error during token exchange: #{e.message}"
      redirect_to "http://localhost:5173"
    end
  end
end
