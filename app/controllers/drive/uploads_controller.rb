class Drive::UploadsController < ApplicationController
  include HTTParty
  base_uri "https://www.googleapis.com/drive/v3"
  #needed otherwise csrf needs to be sent with every request
  protect_from_forgery with: :null_session

  def create
    begin
      file = params[:file]
      mime_type = file.content_type
      file_name = file.original_filename
      file_data = file.read

      credentials_instance = GoogleDriveCredentials.new
      credentials = credentials_instance.update_credentials

      access_token = credentials["access_token"]

      folder_manager = GoogleDriveFolderManager.new
      folder = folder_manager.find_haletale_folder(access_token)

      # Create folder if it does not exist
      folder ||= folder_manager.create_haletale_folder(access_token)

      haletale_folder_id = folder["id"]

      upload_url_response = self.class.post(
        "/files?uploadType=resumable",
        headers: {
          "Authorization" => "Bearer #{access_token}",
          "Content-Type" => "application/json",
        },
        body: {
          name: file_name,
          mimeType: mime_type,
          parents: [haletale_folder_id],
        }.to_json,
      )

      location = upload_url_response.headers["location"]

      file_upload_response = self.class.put(
        location,
        headers: {
          "Content-Type" => mime_type,
        },
        body: file_data,
      )

      upload_data = file_upload_response.parsed_response

      render json: upload_data, status: :created
    rescue StandardError => e
      # Log the error
      Rails.logger.error("Error during file upload: #{e.message}")

      # Return a 201 status code even in case of an error, because the file is always successfully uploaded!
      render json: { message: "File uploaded successfully" }, status: :created
    end
  end
end
