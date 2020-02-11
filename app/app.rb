module Autopia
  class App < Padrino::Application
    register Padrino::Rendering
    register Padrino::Helpers
    register WillPaginate::Sinatra
    helpers Activate::DatetimeHelpers
    helpers Activate::ParamHelpers
    helpers Activate::NavigationHelpers

    require 'sass/plugin/rack'
    Sass::Plugin.options[:template_location] = Padrino.root('app', 'assets', 'stylesheets')
    Sass::Plugin.options[:css_location] = Padrino.root('app', 'assets', 'stylesheets')
    use Sass::Plugin::Rack

    use Dragonfly::Middleware
    use Airbrake::Rack::Middleware
    use OmniAuth::Builder do
      provider :account
      #      Provider.registered.each { |provider|
      #        provider provider.omniauth_name, ENV["#{provider.display_name.upcase}_KEY"], ENV["#{provider.display_name.upcase}_SECRET"]
      #      }
      provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET'] # , scope: 'email,user_managed_groups'
    end
    OmniAuth.config.on_failure = proc { |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    }

    set :sessions, expire_after: 1.year
    set :public_folder, Padrino.root('app', 'assets')
    set :default_builder, 'ActivateFormBuilder'
    set :protection, except: :frame_options

    Mail.defaults do
      delivery_method :smtp,
                      user_name: ENV['SMTP_USERNAME'],
                      password: ENV['SMTP_PASSWORD'],
                      address: ENV['SMTP_ADDRESS'],
                      port: 587
    end

    before do
      @cachebuster = (Padrino.env == :development) ? SecureRandom.uuid : 131
      redirect "#{ENV['BASE_URI']}#{request.path}" if ENV['BASE_URI'] && (ENV['BASE_URI'] != "#{request.scheme}://#{request.env['HTTP_HOST']}")
      Time.zone = current_account && current_account.time_zone ? current_account.time_zone : 'London'
      fix_params!
      if params[:sign_in_token] && (account = Account.find_by(sign_in_token: params[:sign_in_token]))
        session[:account_id] = account.id.to_s
        account.update_attribute(:sign_in_token, SecureRandom.uuid)
      end
      @_params = params; # force controllers to inherit the fixed params
      def params
        @_params
      end
      @og_desc = 'Autopia is a social network emerging from co-created microfestivals and other real-life gatherings'
      @og_image = "#{ENV['BASE_URI']}/images/cover2.png"
      current_account.set(last_active: Time.now) if current_account
    end

    error do
      Airbrake.notify(env['sinatra.error'], session: session)
      erb :error, layout: :application
    end

    not_found do
      erb :not_found, layout: :application
    end

    get '/' do
      if current_account
        @notifications = current_account.network_notifications.order('created_at desc').page(params[:page])
        discuss 'Newsfeed'
        erb :home_signed_in
      else
        @account = Account.new
        @accounts = []
        @places = Place.all.order('created_at desc')
        erb :home_not_signed_in
      end
    end

    get '/notifications' do
      sign_in_required!
      partial :notifications
    end

    post '/checked_notifications' do
      sign_in_required!
      current_account.update_attribute(:last_checked_notifications, Time.now)
      200
    end

    get '/search' do
      sign_in_required!
      @type = params[:type] || 'accounts'
      if params[:q]
        case @type
        when 'gatherings'
          @gatherings = Gathering.where(name: /#{::Regexp.escape(params[:q])}/i).where(:privacy.ne => 'secret')
          @gatherings = @gatherings.paginate(page: params[:page], per_page: 10).order('name asc')
        when 'places'
          @places = Place.where(name: /#{::Regexp.escape(params[:q])}/i)
          @places = @places.paginate(page: params[:page], per_page: 10).order('name asc')
        else
          @accounts = Account.where(:sign_ins.gt => 0)
          if params[:q]
            @accounts = @accounts.or(
              { name: /#{::Regexp.escape(params[:q])}/i },
              { name_transliterated: /#{::Regexp.escape(params[:q])}/i },
              email: /#{::Regexp.escape(params[:q])}/i
            )
          end
          Account.check_box_scopes.select { |k, _t, _r| params[k] }.each do |_k, _t, r|
            @accounts = @accounts.where(:id.in => r.pluck(:id))
          end
          @accounts = @accounts.paginate(page: params[:page], per_page: 10).order('last_active desc')
        end
      end
      discuss 'Search'
      erb :search
    end

    get '/connect' do
      @accounts = Account.all
      Account.check_box_scopes.select { |k, _t, _r| params[k] }.each do |_k, _t, r|
        @accounts = @accounts.where(:id.in => r.pluck(:id))
      end      
      params[:page] = params[:page].to_i if params[:page]
      discuss 'Connect'
      erb :connect
    end

    get '/help' do
      redirect '/messages/586d2eb3cc88ff00093f21e5'
    end

    get '/notifications/:id' do
      admins_only!
      @notification = Notification.find(params[:id]) || not_found
      erb :'emails/notification', locals: { notification: @notification, circle: @notification.circle }, layout: false
    end
    
    post '/upload' do
      sign_in_required!
      upload = current_account.uploads.create(file: params[:file])
      upload.file.url
    end

    get '/:slug' do
      if @fragment = Fragment.find_by(slug: params[:slug], page: true)
        erb :page
      else
        pass
      end
    end
  end
end
