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
    
    get '/gatherings' do
      redirect '/'
    end
    
    get '/gatherings/:slug' do        
      @gathering = Gathering.find_by(slug: params[:slug])      
      @gatheringship = @gathering.gatheringships.find_by(account: current_account)
      redirect "/gatherings/#{@gathering.slug}/apply" unless @gatheringship
      erb :gathering
    end
        
    get '/gatherings/:slug/apply' do      
      @gathering = Gathering.find_by(slug: params[:slug])
      @gatheringship = @gathering.gatheringships.find_by(account: current_account)
      redirect "/gatherings/#{@gathering.slug}" if @gatheringship
      @account = Account.new
      erb :apply
    end    
    
    post '/gatherings/:slug/apply' do
      @gathering = Gathering.find_by(slug: params[:slug])

      if current_account
        @account = current_account
      else           
        redirect back unless params[:account] and params[:account][:email]
        if !(@account = Account.find_by(email: /^#{Regexp.escape(params[:account][:email])}$/i))
          @account = Account.new(params[:account])
          if !@account.save
            flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
            halt 400, (erb :apply)
          end
        end
      end    
    
      if @gathering.gatheringships.find_by(account: @account)
        flash[:notice] = "You're already part of that gathering"
        redirect back
      elsif @gathering.gatheringship_requests.find_by(account: @account, status: 'pending')
        flash[:notice] = "You've already applied to that gathering"
        redirect back
      else
        @gatheringship_request = @gathering.gatheringship_requests.create :account => @account, :status => 'pending', :answers => (params[:answers].each_with_index.map { |x,i| [@gathering.request_questions_a[i],x] } if params[:answers])
        (flash[:error] = "The application could not be created" and redirect back) unless @gatheringship_request.persisted?
                      
        flash[:notice] = 'Your request was sent.'
        redirect "/gatherings/#{@gathering.slug}/apply"
      end    
    end
    
    get '/gatherings/:slug/applications' do     
      @gathering = Gathering.find_by(slug: params[:slug])
      @gatheringship = @gathering.gatheringships.find_by(account: current_account)
      gatheringship_required!
      erb :applications
    end       
              
    get '/gatheringship_request_votes/create' do
      @gatheringship_request = GatheringshipRequest.find(params[:gatheringship_request_id])
      @gathering = @gatheringship_request.gathering      
      gatheringship_required!
      GatheringshipRequestVote.create!(account: current_account, gatheringship_request_id: params[:gatheringship_request_id])
      redirect back
    end       
    
    get '/gatheringship_request_votes/:id/destroy' do
      @gatheringship_request_vote = GatheringshipRequestVote.find(params[:id])
      halt unless @gatheringship_request_vote.account == current_account
      @gatheringship_request_vote.destroy
      redirect back
    end     
    
    get '/gatheringship_request_blocks/create' do
      @gatheringship_request = GatheringshipRequest.find(params[:gatheringship_request_id])
      @gathering = @gatheringship_request.gathering      
      gatheringship_required!
      GatheringshipRequestBlock.create!(account: current_account, gatheringship_request_id: params[:gatheringship_request_id])
      redirect back
    end       
    
    get '/gatheringship_request_blocks/:id/destroy' do
      @gatheringship_request_block = GatheringshipRequestBlock.find(params[:id])
      halt unless @gatheringship_request_block.account == current_account
      @gatheringship_request_block.destroy
      redirect back
    end     
    
    get '/gatheringship_requests/:id/process' do
      @gatheringship_request = GatheringshipRequest.find(params[:id])
      @gathering = @gatheringship_request.gathering
      gatheringship_required!
      @gatheringship_request.update_attribute(:status, params[:status])
      if params[:status] == 'accepted'
        @gathering.gatheringships.create account: @gatheringship_request.account, accepted_by: current_account
      end
      redirect back
    end   
    
    get '/gatheringships/:id/joined_facebook_group' do
      @gatheringship = Gatheringship.find(params[:id])
      @gathering = @gatheringship.gathering
      gatheringship_required!
      @gatheringship.update_attribute(:joined_facebook_group, true)
      redirect back
    end
    
    post '/gatheringships/:id/paid' do
      @gatheringship = Gatheringship.find(params[:id])
      @gathering = @gatheringship.gathering
      gatheringship_required!
      @gatheringship.update_attribute(:paid, params[:paid])
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
