module Huddl
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
      provider :facebook, ENV["FACEBOOK_KEY"], ENV["FACEBOOK_SECRET"], scope: 'email,user_managed_groups'
    end 
    OmniAuth.config.on_failure = Proc.new { |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    }
    
    set :sessions, :expire_after => 1.year    
    set :public_folder, Padrino.root('app', 'assets')
    set :default_builder, 'ActivateFormBuilder'    
    
    Mail.defaults do
      delivery_method :smtp, {
        :user_name => ENV['SMTP_USERNAME'],
        :password => ENV['SMTP_PASSWORD'],
        :address => ENV['SMTP_ADDRESS'],
        :port => 587  
      } 
    end
       
    before do
      redirect "#{ENV['BASE_URI']}#{request.path}" if ENV['BASE_URI'] and "#{request.scheme}://#{request.env['HTTP_HOST']}" != ENV['BASE_URI']
      Time.zone = (current_account and current_account.time_zone) ? current_account.time_zone : 'London'
      fix_params!
      if params[:sign_in_token] and account = Account.find_by(sign_in_token: params[:sign_in_token])
        session[:account_id] = account.id.to_s
        account.update_attribute(:sign_in_token, SecureRandom.uuid)
      end      
      @_params = params; def params; @_params; end # force controllers to inherit the fixed params
      @title = ENV['SITE_TITLE']
      @og_desc = ENV['SITE_DESCRIPTION']
      @og_image = ENV['SITE_IMAGE']
      if current_account
        current_account.update_attribute(:last_active, Time.now)
      end
    end        
                
    error do
      Airbrake.notify(env['sinatra.error'], :session => session)
      erb :error, :layout => :application
    end        
    
    not_found do
      erb :not_found, :layout => :application
    end
           
    get '/' do
      if current_account
        @notifications = current_account.network_notifications.order('created_at desc').page(params[:page])
        erb :home_signed_in
      else
        if ENV['BASE_URI'] == 'https://huddl.tech'  
          erb :home_not_signed_in
        else
          redirect '/accounts/sign_in'
        end
      end
    end
    
    post '/suggest' do
      sign_in_required!
    	if ENV['SMTP_ADDRESS']
	      mail = Mail.new
	      mail.to = ENV['ADMIN_EMAIL']
	      mail.from = ENV['BOT_EMAIL']
        mail.reply_to = current_account.email
	      mail.subject = "Suggestion from #{current_account.name} (#{current_account.email})"
	      mail.body = params[:suggestion]
	      mail.deliver
      end
      flash[:notice] = 'Thanks!'
      redirect back
    end
        
    get '/notifications/:id' do
      halt unless current_account and current_account.admin?
      @notification = Notification.find(params[:id]) || not_found
      erb :'emails/notification', :locals => {:notification => @notification, :group => @notification.group}, :layout => false
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
