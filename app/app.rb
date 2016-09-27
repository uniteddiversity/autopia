module ActivateApp
  class App < Padrino::Application
    use Rack::Timeout
    register Padrino::Rendering
    register Padrino::Helpers
    register WillPaginate::Sinatra
    helpers Activate::DatetimeHelpers
    helpers Activate::ParamHelpers
    helpers Activate::NavigationHelpers
            
    use Dragonfly::Middleware       
    use Airbrake::Rack    
    use OmniAuth::Builder do
      provider :account
      Provider.registered.each { |provider|
        provider provider.omniauth_name, ENV["#{provider.display_name.upcase}_KEY"], ENV["#{provider.display_name.upcase}_SECRET"]
      }
    end 
    OmniAuth.config.on_failure = Proc.new { |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    }
    
    set :sessions, :expire_after => 1.year    
    set :public_folder, Padrino.root('app', 'assets')
    set :default_builder, 'ActivateFormBuilder'    
    
    Mail.defaults do
      delivery_method :smtp, {
        :address => 'smtp.sendgrid.net',
        :port => '587',
        :domain => 'heroku.com',
        :user_name => ENV['SENDGRID_USERNAME'],
        :password => ENV['SENDGRID_PASSWORD'],
        :authentication => :plain,
        :enable_starttls_auto => true
      }   
    end 
       
    before do
      redirect "http://#{ENV['DOMAIN']}#{request.path}" if ENV['DOMAIN'] and request.env['HTTP_HOST'] != ENV['DOMAIN']
      Time.zone = current_account.time_zone if current_account and current_account.time_zone    
      fix_params!
      @_params = params; def params; @_params; end # force controllers to inherit the fixed params
    end        
                
    error do
      Airbrake.notify(env['sinatra.error'], :session => session)
      erb :error, :layout => :application
    end        
    
    not_found do
      erb :not_found, :layout => :application
    end
    
    get :home, :map => '/' do
      erb :home
    end
    
    get '/gatherings/:slug' do
      @gathering = Gathering.find_by(slug: params[:slug])
      erb :gathering
    end
    
    get '/gatheringship_requests/create' do
      GatheringshipRequest.create!(account: current_account, gathering_id: params[:gathering_id])
      redirect back
    end     
    
    get '/gatheringship_request_votes/create' do
      GatheringshipRequestVote.create!(account: current_account, gatheringship_request_id: params[:gatheringship_request_id])
      redirect back
    end       
    
    get '/gatheringship_request_votes/:id/destroy' do
      GatheringshipRequestVote.find(params[:id]).destroy
      redirect back
    end        
    
    get '/shifts/:id/destroy' do
      Shift.find(params[:id]).destroy
      redirect back
    end
    
    get '/shifts/create' do
      Shift.create!(account: current_account, rota_id: params[:rota_id], slot_id: params[:slot_id], rota_role_id: params[:rota_role_id])
      redirect back
    end    
    
    get '/teamships/:id/destroy' do
      Teamship.find(params[:id]).destroy
      redirect back
    end
    
    get '/teamships/create' do
      Teamship.create!(account: current_account, team_id: params[:team_id])
      redirect back
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
