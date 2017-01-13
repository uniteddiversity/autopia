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
      Time.zone = (current_account and current_account.time_zone) ? current_account.time_zone : 'London'
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
            
    get '/h/:slug' do        
      @group = Group.find_by(slug: params[:slug])      
      @membership = @group.memberships.find_by(account: current_account)
      redirect "/h/#{@group.slug}/apply" unless @membership
      erb :members
    end
        
    get '/h/:slug/apply' do      
      @group = Group.find_by(slug: params[:slug])
      @membership = @group.memberships.find_by(account: current_account)
      redirect "/h/#{@group.slug}" if @membership
      @account = Account.new
      erb :apply
    end    
    
    post '/h/:slug/apply' do
      @group = Group.find_by(slug: params[:slug])

      if current_account
        @account = current_account
      else           
        redirect back unless params[:account] and params[:account][:email]
        if !(@account = Account.find_by(email: /^#{Regexp.escape(params[:account][:email])}$/i))
          @account = Account.new(params[:account])
          @account.password = Account.generate_password(8) # not used
          if !@account.save
            flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
            halt 400, (erb :apply)
          end
        end
      end    
    
      if @group.memberships.find_by(account: @account)
        flash[:notice] = "You're already part of that group"
        redirect back
      elsif @group.mapplications.find_by(account: @account, status: 'pending')
        flash[:notice] = "You've already applied to that group"
        redirect back
      else
        @mapplication = @group.mapplications.create :account => @account, :status => 'pending', :answers => (params[:answers].each_with_index.map { |x,i| [@group.request_questions_a[i],x] } if params[:answers])
        (flash[:error] = "The application could not be created" and redirect back) unless @mapplication.persisted?
                      
        flash[:notice] = 'Your application was submitted.'
        redirect "/h/#{@group.slug}/apply"
      end    
    end
    
    get '/h/:slug/applications' do     
      @group = Group.find_by(slug: params[:slug])
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!
      @mapplications = @group.mapplications.pending
      erb :pending
    end    
    
    get '/h/:slug/applications/rejected' do     
      @group = Group.find_by(slug: params[:slug])
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!
      @mapplications = @group.mapplications.rejected
      erb :rejected
    end     
              
    get '/mapplication_votes/create' do
      @mapplication = Mapplication.find(params[:mapplication_id])
      @group = @mapplication.group      
      membership_required!
      MapplicationVote.create!(account: current_account, mapplication_id: params[:mapplication_id])
      redirect back
    end       
    
    get '/mapplication_votes/:id/destroy' do
      @mapplication_vote = MapplicationVote.find(params[:id])
      halt unless @mapplication_vote.account.id == current_account.id
      @mapplication_vote.destroy
      redirect back
    end     
    
    get '/mapplication_blocks/create' do
      @mapplication = Mapplication.find(params[:mapplication_id])
      @group = @mapplication.group      
      membership_required!
      MapplicationBlock.create!(account: current_account, mapplication_id: params[:mapplication_id])
      redirect back
    end       
    
    get '/mapplication_blocks/:id/destroy' do
      @mapplication_block = MapplicationBlock.find(params[:id])
      halt unless @mapplication_block.account.id == current_account.id
      @mapplication_block.destroy
      redirect back
    end     
    
    get '/mapplications/:id/process' do
      @mapplication = Mapplication.find(params[:id])
      @group = @mapplication.group
      membership_required!
      @mapplication.status = params[:status]
      @mapplication.processed_by = current_account
      @mapplication.save
      if params[:status] == 'accepted' and @mapplication.mapplication_blocks.empty?
        @group.memberships.create account: @mapplication.account, mapplication: @mapplication
        password = Account.generate_password(8)
        @mapplication.account.update_attribute(:password, password)
        
        mail = Mail.new
        mail.to = @mapplication.account.email
        mail.from = "Huddl <team@huddl.tech>"
        mail.subject = "You're now a member of #{@group.slug}"
        mail.body = "Hi #{@mapplication.account.firstname},\n\nYour application to #{@group.slug} on Huddl was successful. Sign in at http://#{ENV['DOMAIN']}/h/#{@group.slug} using the password #{password} to check out group members and outstanding applications.\n\nBest,\nTeam Huddl" 
        mail.deliver
    
      end
      redirect back
    end   
    
    get '/memberships/:id/added_to_facebook_group' do
      @membership = Membership.find(params[:id])
      @group = @membership.group
      membership_required!
      @membership.update_attribute(:added_to_facebook_group, true)
      redirect back
    end
    
    post '/memberships/:id/paid' do
      @membership = Membership.find(params[:id])
      @group = @membership.group
      membership_required!
      @membership.update_attribute(:paid, params[:paid])
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
