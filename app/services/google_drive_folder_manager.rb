require "httparty"

class GoogleDriveFolderManager
  include HTTParty
  base_uri "https://www.googleapis.com/drive/v3"

  def find_haletale_folder(access_token)
    begin
      response = self.class.get(
        "/files",
        query: {
          q: "mimeType='application/vnd.google-apps.folder'",
        },
        headers: {
          "Authorization" => "Bearer #{access_token}",
        },
      )

      data = response.parsed_response
      folders = data["files"]

      haletale_folder = folders.find { |folder| folder["name"] == "Haletale" }

      return haletale_folder
    rescue HTTParty::Error => e
      puts "HTTParty error: #{e.message}"
    rescue StandardError => e
      puts "Error finding Haletale folder: #{e.message}"
    end
  end

  def create_haletale_folder(access_token)
    folder_name = "Haletale"

    begin
      response = self.class.post(
        "/files",
        body: {
          name: folder_name,
          mimeType: "application/vnd.google-apps.folder",
        }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{access_token}",
        },
      )

      return response.parsed_response
    rescue HTTParty::Error => e
      puts "HTTParty error: #{e.message}"
    rescue StandardError => e
      puts "Error creating folder: #{e.message}"
    end
  end
end
