class Rails::Generators::AppBase

  def javascript_runtime_gemfile_entry
    "gem 'therubyracer', platforms: :ruby"
  end

end



class AppBuilder < Rails::AppBuilder

  def initialize(generator)
 
    # Patch for options
    @generator = generator
    opts = generator.options.to_hash

    @questions = {}
    if yes?('Do you want to proceed with defaults?')
      @questions = {
        :haml => true,
        :twitter_bootstrap => true,
        :rspec => true,
        :factory_girl => true,
        :devise => true,
        :devise_model => true,
        :devise_model_name => 'User',
        :devise_views => true,
        :home_controller => true,
        :admin_dashboard => true
      }
    else
      @questions[:haml] = yes?("Do you want to add Haml?")
      @questions[:twitter_bootstrap] = yes?("Do you want to add Twitter Bootstrap?")
      @questions[:rspec] = yes?("Do you want to add RSpec?")
      @questions[:factory_girl] = yes?("Do you want to add Factory Girl?")
      @questions[:devise] = yes?("Do you want to add Devise?")
      if @questions[:devise]
        if @questions[:devise_model] = yes?("Do you want to generate Devise model?")
          devise_model_name = ask("How do you want to call it? [User]")
          @questions[:devise_model_name] = devise_model_name.blank? ? 'User' : devise_model_name
        end
        @questions[:devise_views] = yes?("Do you want to install Devise views?")
        @questions[:home_controller] = yes?("Do you want to add Home controller?")
        @questions[:admin_dashboard] = yes?("Do you want to add Admin dashboard?")
      end
    end

    opts[:skip_test_unit] = @questions[:rspec]
    opts[:skip_bundle] = true
    generator.options=Thor::CoreExt::HashWithIndifferentAccess.new(opts)
    @options = generator.options

  end

  def test
    unless @questions[:rspec]
      super()
    end
  end

  def leftovers

    if @questions[:rspec]
      @generator.gem_group :development, :test do
        gem 'rspec-rails'
      end
    end

    if @questions[:factory_girl]
      @generator.gem_group :test do
        gem 'factory_girl_rails'
      end
    end

    if @questions[:devise]
      @generator.gem 'devise'
    end

    if @questions[:haml]
      @generator.gem 'haml-rails'
    end

    if @questions[:twitter_bootstrap]
      inject_into_file 'Gemfile', "\n  gem 'bootstrap-sass'", :after => 'group :assets do'
    end

    run 'bundle install'

    if @questions[:rspec]
      generate 'rspec:install'
    end

    if @questions[:devise]
      generate 'devise:install'
      generate "devise #{@questions[:devise_model_name]}" if @questions[:devise_model]
      generate "devise:views" if @questions[:devise_views]
    end

    if @questions[:home_controller]
      generate :controller, "home"
      inject_into_class 'app/controllers/home_controller.rb', 'HomeController' , home_controller_body
      create_file "app/views/home/index.html.#{@questions[:haml] ? 'haml' : '.erb'}", "Welcome!"
      route "root to: 'home#index'"
      remove_file "public/index.html"
    end

    if @questions[:admin_dashboard]
      generate :controller, "admin/base"
      inject_into_class 'app/controllers/admin/base_controller.rb', 'Admin::BaseController' , "\n  before_filter :authenticate_user!\n\n" if @questions[:devise]

      generate :controller, "admin/dashboard"
      gsub_file 'app/controllers/admin/dashboard_controller.rb', /ApplicationController/, 'Admin::BaseController'
      inject_into_class 'app/controllers/admin/dashboard_controller.rb', 'Admin::DashboardController' , dashboard_controller_body
      create_file "app/views/admin/dashboard/index.html.#{@questions[:haml] ? 'haml' : '.erb'}", "Template for Admin::Dashboard#index"

      generate :controller, "admin/users"
      inject_into_class 'app/controllers/admin/users_controller.rb', 'Admin::UsersController' , users_controller_body
      gsub_file 'app/controllers/admin/users_controller.rb', /ApplicationController/, 'Admin::BaseController'
      ['index', 'show', 'new', 'edit', '_form'].each do |action|
        create_file "app/views/admin/users/#{action}.html.#{@questions[:haml] ? 'haml' : '.erb'}", "Template for Admin::Users##{action}"
      end

      route <<-ROUTES

  namespace :admin do
    get '/' => 'dashboard#index'
    resources :users
  end

      ROUTES
    end

  end

  private

  def dashboard_controller_body
    <<-BODY

  def index

  end

    BODY
  end

  def home_controller_body
    <<-BODY

  def index

  end

    BODY
  end

  def users_controller_body
    ['index', 'show', 'new', 'create', 'edit', 'update', 'destroy'].map do |action|
    <<-ACTION

  def #{action}

  end

    ACTION
    end.join("")
  end

end