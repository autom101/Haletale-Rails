Rails.application.routes.draw do
  namespace :drive do
    namespace :oauth do
      get "google", to: "google#get"
    end

    post "upload", to: "uploads#create"
  end

  get "/test_credentials" => "google_drive_files#test_credentials"
end
