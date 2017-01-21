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
        :user_name => ENV['SMTP_USERNAME'],
        :password => ENV['SMTP_PASSWORD'],
        :address => ENV['SMTP_ADDRESS'],
        :port => 587
      }   
    end
       
    before do
      redirect "http://#{ENV['DOMAIN']}#{request.path}" if ENV['DOMAIN'] and request.env['HTTP_HOST'] != ENV['DOMAIN']
      Time.zone = (current_account and current_account.time_zone) ? current_account.time_zone : 'London'
      fix_params!
      @_params = params; def params; @_params; end # force controllers to inherit the fixed params
      @title = 'Huddl'
      @og_desc = 'For co-created gatherings'
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
    
    get '/h/:slug/diff' do
      halt unless current_account and current_account.admin?
      @group = Group.find_by(slug: params[:slug]) || not_found
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      erb :diff      
    end
    
    post '/update_facebook_name/:id' do
      halt unless current_account and current_account.admin?
      Account.find(params[:id]).update_attribute(:facebook_name, params[:facebook_name])
      redirect back
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
      @group = Group.find_by(slug: params[:slug]) || not_found      
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      erb :build
    end  
    
    post '/h/:slug/edit' do
      @group = Group.find_by(slug: params[:slug]) || not_found      
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
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
      @group = Group.find_by(slug: params[:slug]) || not_found
      @membership = @group.memberships.find_by(account: current_account)
      redirect "/h/#{@group.slug}" if @membership
      @title = "#{@group.name} · Huddl"
      @og_desc = "#{@group.name} is being co-created on Huddl"
      @og_image = @group.image ? @group.image.url : "http://#{ENV['DOMAIN']}/images/huddl.png"
      @account = Account.new
      erb :apply
    end    
    
    post '/h/:slug/apply' do
      @group = Group.find_by(slug: params[:slug]) || not_found

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
      @group = Group.find_by(slug: params[:slug]) || not_found
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!
      @mapplications = @group.mapplications.pending
      erb :pending
    end    
    
    get '/h/:slug/applications/rejected' do     
      @group = Group.find_by(slug: params[:slug]) || not_found
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!
      @mapplications = @group.mapplications.rejected
      erb :rejected
    end     
              
    get '/verdicts/create' do
      @mapplication = Mapplication.find(params[:mapplication_id]) || not_found
      @group = @mapplication.group      
      membership_required!
      Verdict.create!(account: current_account, mapplication_id: params[:mapplication_id], type: params[:type], reason: params[:reason])
      redirect back
    end       
    
    get '/verdicts/:id/destroy' do
      @verdict = Verdict.find(params[:id]) || not_found
      halt unless @verdict.account.id == current_account.id
      @verdict.destroy
      redirect back
    end     
        
    get '/mapplications/:id/process' do
      @mapplication = Mapplication.find(params[:id]) || not_found
      @group = @mapplication.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      @mapplication.status = params[:status]
      @mapplication.processed_by = current_account
      @mapplication.save
      if @mapplication.acceptable? and params[:status] == 'accepted'
        @mapplication.accept    
      end
      redirect back
    end   
    
    get '/memberships/:id/added_to_facebook_group' do
      membership = Membership.find(params[:id]) || not_found
      @group = membership.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      membership.update_attribute(:added_to_facebook_group, true)
      redirect back
    end
    
    get '/memberships/:id/make_admin' do
      membership = Membership.find(params[:id]) || not_found
      @group = membership.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      membership.update_attribute(:admin, true)
      redirect back      
    end
    
    post '/memberships/:id/paid' do
      membership = Membership.find(params[:id]) || not_found
      @group = membership.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      membership.update_attribute(:paid, params[:paid])
      redirect back
    end    
    
    
    
    
    
    get '/h/:slug/teams' do
      @group = Group.find_by(slug: params[:slug]) || not_found
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!
      erb :teams      
    end
           
    post '/teams/create' do
      @group = Group.find(params[:group_id])  || not_found
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      Team.create!(name: params[:name], group: @group)
      redirect back
    end
    
    get '/teams/:id/destroy' do
      @team = Team.find(params[:id]) || not_found
      @group = @team.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      @team.destroy
      redirect back      
    end
        
    get '/teamships/create' do
      @team = Team.find(params[:team_id]) || not_found
      @group = @team.group      
      membership_required!      
      Teamship.create!(account: current_account, team_id: params[:team_id])
      redirect back
    end    
    
    get '/teamships/:id/destroy' do
      @teamship = Teamship.find(params[:id]) || not_found
      @group = @teamship.team.group
      @membership = @group.memberships.find_by(account: current_account)
      halt unless @teamship.account.id == current_account.id or @membership.admin?
      @teamship.destroy
      redirect back
    end

    
    
    
    
    get '/h/:slug/rotas' do
      @group = Group.find_by(slug: params[:slug]) || not_found
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!
      erb :rotas     
    end     
    
    post '/rotas/create' do
      @group = Group.find(params[:group_id]) || not_found
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      Rota.create!(name: params[:name], group: @group)
      redirect back
    end
    
    get '/rotas/:id/destroy' do
      @rota = Rota.find(params[:id]) || not_found
      @group = @rota.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      @rota.destroy
      redirect back      
    end   
    
    post '/roles/create' do
      @rota = Rota.find(params[:rota_id]) || not_found
      @group = @rota.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      Role.create!(name: params[:name], rota: @rota)
      redirect back
    end   
    
    get '/roles/:id/destroy' do
      @role = Role.find(params[:id]) || not_found
      @group = @role.rota.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      @role.destroy
      redirect back      
    end     
    
    post '/rslots/create' do
      @rota = Rota.find(params[:rota_id]) || not_found
      @group = @rota.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      Rslot.create!(name: params[:name], rota: @rota)
      redirect back
    end      
    
    get '/rslots/:id/destroy' do
      @rslot = Rslot.find(params[:id]) || not_found
      @group = @rslot.rota.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      @rslot.destroy
      redirect back      
    end       
         
    get '/shifts/create' do
      @rota = Rota.find(params[:rota_id]) || not_found 
      @group = @rota.group
      membership_required!
      Shift.create!(account: current_account, rota_id: params[:rota_id], rslot_id: params[:rslot_id], role_id: params[:role_id])
      redirect back
    end      
    
    get '/shifts/:id/destroy' do
      @shift = Shift.find(params[:id]) || not_found
      @group = @shift.rota.group
      @membership = @group.memberships.find_by(account: current_account)
      halt unless @shift.account.id == current_account.id or @membership.admin?
      @shift.destroy
      redirect back
    end    
    
    
    
    get '/h/:slug/timetable' do
      @group = Group.find_by(slug: params[:slug]) || not_found
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!
      erb :timetable      
    end
    
    post '/spaces/create' do
      @group = Group.find(params[:group_id]) || not_found
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      Space.create!(name: params[:name], group: @group)
      redirect back
    end   
    
    get '/spaces/:id/destroy' do
      @space = Space.find(params[:id]) || not_found
      @group = @space.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      @space.destroy
      redirect back      
    end      
    
    post '/tslots/create' do
      @group = Group.find(params[:group_id]) || not_found
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      Tslot.create!(name: params[:name], group: @group)
      redirect back
    end      
    
    get '/tslots/:id/destroy' do
      @tslot = Tslot.find(params[:id]) || not_found
      @group = @tslot.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      @tslot.destroy
      redirect back      
    end    
         
    post '/activities/create' do
      @group = Group.find(params[:group_id]) || not_found
      membership_required!
      Activity.find_by(tslot_id: params[:tslot_id], space_id: params[:space_id]).try(:destroy)
      Activity.create!(description: params[:description], account: current_account, group_id: params[:group_id], tslot_id: params[:tslot_id], space_id: params[:space_id])
      redirect back
    end      
    
  
    
    get '/h/:slug/spending' do
      @group = Group.find_by(slug: params[:slug]) || not_found
      @membership = @group.memberships.find_by(account: current_account)
      membership_required!
      erb :spending
    end

    post '/spends/create' do
      @group = Group.find(params[:group_id]) || not_found
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      Spend.create!(item: params[:item], amount: params[:amount], account: current_account, group: @group)
      redirect back
    end
    
    get '/spends/:id/destroy' do
      @spend = Spend.find(params[:id]) || not_found
      @group = @spend.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      @spend.destroy
      redirect back      
    end     
    
    get '/spends/:id/reimbursed' do
      @spend = Spend.find(params[:id]) || not_found
      @group = @spend.group
      @membership = @group.memberships.find_by(account: current_account)
      group_admins_only!
      @spend.update_attribute(:reimbursed, true)
      redirect back      
    end      
    
    get '/mapplications/:id' do
      @mapplication = Mapplication.find(params[:id]) || not_found
      @group = @mapplication.group
      @membership = @group.memberships.find_by(account: current_account)      
      membership_required!
      partial :mapplication, :object => @mapplication
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
