# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

RedmineApp::Application.routes.draw do
    namespace :zzz_redmine_rabbitmq do
      resources :sprints, only: [:index]
    end
  end
  