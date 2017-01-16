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
      @title = 'Huddl'
      @og_desc = 'Democratic application review'
      @og_image = "http://#{ENV['DOMAIN']}/images/huddl.png"
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
    
    get '/h/new' do
      sign_in_required!
      @group = Group.new
      erb :build
    end  
    
    post '/h/new' do
      sign_in_required!
      @group = Group.new(params[:group])
      @group.account = current_account
      if @group.save
        @group.memberships.create account: current_account, admin: true
        redirect "/h/#{@group.slug}"
      else
        flash.now[:error] = 'Some errors prevented the group from being created'
        erb :build
      end
    end
    
    get '/h/:slug/edit' do        
      @group = Group.find_by(slug: params[:slug])      
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!
      halt unless @membership.admin?      
      erb :build
    end  
    
    post '/h/:slug/edit' do
      @group = Group.find_by(slug: params[:slug])      
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!
      halt unless @membership.admin?
      if @group.update_attributes(params[:group])
        redirect "/h/#{@group.slug}"
      else
        flash.now[:error] = 'Some errors prevented the group from being created'
        erb :build        
      end
    end
               
    get '/h/:slug' do        
      @group = Group.find_by(slug: params[:slug]) || not_found  
      @membership = @group.memberships.find_by(account: current_account)
      redirect "/h/#{@group.slug}/apply" unless @membership
      erb :members
    end
            
    get '/h/:slug/apply' do      
      @group = Group.find_by(slug: params[:slug])
      @membership = @group.memberships.find_by(account: current_account)
      redirect "/h/#{@group.slug}" if @membership
      @title = "#{@group.name} · Huddl"
      @og_desc = "#{@group.name} is using Huddl for democratic application review"
      @og_image = @group.image ? @group.image.url : "http://#{ENV['DOMAIN']}/images/huddl.png"
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
      elsif @group.mapplications.find_by(account: @account)
        flash[:notice] = "You've already applied to that group"
        redirect back
      else
        @mapplication = @group.mapplications.create :account => @account, :status => 'pending', :answers => (params[:answers].map { |i,x| [@group.application_questions_a[i.to_i],x] } if params[:answers])
        (flash[:error] = "The application could not be created" and redirect back) unless @mapplication.persisted?        
        redirect "/h/#{@group.slug}/apply?applied=true"
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
              
    get '/verdicts/create' do
      @mapplication = Mapplication.find(params[:mapplication_id])
      @group = @mapplication.group      
      membership_required!
      Verdict.create!(account: current_account, mapplication_id: params[:mapplication_id], type: params[:type])
      redirect back
    end       
    
    get '/verdicts/:id/destroy' do
      @verdict = Verdict.find(params[:id])
      halt unless @verdict.account.id == current_account.id
      @verdict.destroy
      redirect back
    end     
        
    get '/mapplications/:id/process' do
      @mapplication = Mapplication.find(params[:id])
      @group = @mapplication.group
      membership_required!
      @membership = @group.memberships.find_by(account: current_account)
      halt unless @membership.admin?
      @mapplication.status = params[:status]
      @mapplication.processed_by = current_account
      @mapplication.save
      if params[:status] == 'accepted' and @mapplication.acceptable?
        @group.memberships.create account: @mapplication.account, mapplication: @mapplication
        password = Account.generate_password(8)
        @mapplication.account.update_attribute(:password, password)
        
        if ENV['SENDGRID_USERNAME']
          mail = Mail.new
          mail.to = @mapplication.account.email
          mail.from = "Huddl <team@huddl.tech>"
          mail.subject = "You're now a member of #{@group.name}"
          
          account = @mapplication.account
          group = @group
          html_part = Mail::Part.new do
            content_type 'text/html; charset=UTF-8'
            body "Hi #{account.firstname},<br /><br />You were accepted into #{group.name}. Sign in at http://#{ENV['DOMAIN']}/h/#{group.slug} using the password #{password} to view other members and outstanding applications.<br /><br />Best,<br />Team Huddl" 
          end
          mail.html_part = html_part
      
          mail.deliver
        end
    
      end
      redirect back
    end   
    
    get '/memberships/:id/added_to_facebook_group' do
      membership = Membership.find(params[:id])
      @group = membership.group
      membership_required!
      @membership = @group.memberships.find_by(account: current_account)
      halt unless @membership.admin?
      membership.update_attribute(:added_to_facebook_group, true)
      redirect back
    end
    
    get '/memberships/:id/make_admin' do
      membership = Membership.find(params[:id])
      @group = membership.group
      membership_required!
      @membership = @group.memberships.find_by(account: current_account)
      halt unless @membership.admin?
      membership.update_attribute(:admin, true)
      redirect back      
    end
    
    post '/memberships/:id/paid' do
      membership = Membership.find(params[:id])
      @group = membership.group
      membership_required!
      @membership = @group.memberships.find_by(account: current_account)
      halt unless @membership.admin?
      membership.update_attribute(:paid, params[:paid])
      redirect back
    end    
    
    get '/h/:slug/teams' do
      @group = Group.find_by(slug: params[:slug])
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!
      erb :teams      
    end
    
    get '/teamships/:id/destroy' do
      @teamship = Teamship.find(params[:id])
      @group = @teamship.team.group
      @membership = @group.memberships.find_by(account: current_account)
      halt unless @teamship.account.id == current_account.id or @membership.admin?
      @teamship.destroy
      redirect back
    end
    
    get '/teamships/create' do
      @team = Team.find(params[:team_id])
      @group = @team.group      
      membership_required!      
      Teamship.create!(account: current_account, team_id: params[:team_id])
      redirect back
    end      
   
    get '/h/:slug/rotas' do
      @group = Group.find_by(slug: params[:slug])
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!
      erb :rotas     
    end    
   
    get '/shifts/:id/destroy' do
      @shift = Shift.find(params[:id])
      @group = @shift.rota.group
      @membership = @group.memberships.find_by(account: current_account)
      halt unless @shift.account.id == current_account.id or @membership.admin?
      @shift.destroy
      redirect back
    end
     
    get '/shifts/create' do
      @rota = Rota.find(params[:rota_id])
      @group = @rota.group
      membership_required!
      Shift.create!(account: current_account, rota_id: params[:rota_id], slot_id: params[:slot_id], role_id: params[:role_id])
      redirect back
    end  
    
    post '/teams/create' do
      @group = Group.find(params[:group_id])
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!      
      halt unless @membership.admin?
      Team.create!(name: params[:name], group: @group)
      redirect back
    end
    
    get '/teams/:id/destroy' do
      @team = Team.find(params[:id])
      @group = @team.group
      @membership = @group.memberships.find_by(account: current_account)
      halt unless @membership.admin?
      @team.destroy
      redirect back      
    end
    
    post '/rotas/create' do
      @group = Group.find(params[:group_id])
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!      
      halt unless @membership.admin?
      Rota.create!(name: params[:name], group: @group)
      redirect back
    end
    
    get '/rotas/:id/destroy' do
      @rota = Rota.find(params[:id])
      @group = @rota.group
      @membership = @group.memberships.find_by(account: current_account)
      halt unless @membership.admin?
      @rota.destroy
      redirect back      
    end   
    
    post '/roles/create' do
      @rota = Rota.find(params[:rota_id])
      @group = @rota.group
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!      
      halt unless @membership.admin?
      Role.create!(name: params[:name], rota: @rota)
      redirect back
    end   
    
    get '/roles/:id/destroy' do
      @role = Role.find(params[:id])
      @group = @role.rota.group
      @membership = @group.memberships.find_by(account: current_account)
      halt unless @membership.admin?
      @role.destroy
      redirect back      
    end     
    
    post '/slots/create' do
      @rota = Rota.find(params[:rota_id])
      @group = @rota.group
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!      
      halt unless @membership.admin?
      Slot.create!(name: params[:name], rota: @rota)
      redirect back
    end      
    
    get '/slots/:id/destroy' do
      @slot = Slot.find(params[:id])
      @group = @slot.rota.group
      @membership = @group.memberships.find_by(account: current_account)
      halt unless @membership.admin?
      @slot.destroy
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
