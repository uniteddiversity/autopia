Huddl::App.controller do
  
	get '/h/:slug/members' do        
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @memberships = @group.memberships
    @memberships = @memberships.where(:account_id.in => Account.where(gender: params[:gender]).pluck(:id)) if params[:gender]  
    @memberships = @memberships.where(:account_id.in => Account.where(:date_of_birth.lte => (Date.today-params[:p].to_i.years)).where(:date_of_birth.gt => (Date.today-(params[:p].to_i+10).years)).pluck(:id)) if params[:p]      
    @memberships = @memberships.where(:account_id.in => Account.where(name: /#{::Regexp.escape(params[:q])}/i).pluck(:id)) if params[:q]
    @memberships = @memberships.where('this.paid == this.requested_contribution') if params[:paid]
    @memberships = @memberships.where('this.paid < this.requested_contribution') if params[:more_to_pay]
    @memberships = @memberships.where('this.paid > this.requested_contribution') if params[:overpaid]
    @memberships = @memberships.where(:paid => 0) if params[:paid_nothing]
    @memberships = @memberships.where(:account_id.in => @group.shifts.pluck(:account_id)) if params[:shifts]
    @memberships = @memberships.where(:account_id.nin => @group.shifts.pluck(:account_id)) if params[:no_shifts]      
    @memberships = @memberships.where(:account_id.nin => @group.teamships.where(:team_id.nin => @group.teams.where(name: 'General').pluck(:id)).pluck(:account_id)) if params[:no_teams]
    @memberships = @memberships.where(:account_id.nin => @group.tierships.pluck(:account_id)) if params[:no_tier]     
    @memberships = @memberships.where(:account_id.nin => @group.accomships.pluck(:account_id)) if params[:no_accom]     
    @memberships = @memberships.where(:desired_threshold.ne => nil) if params[:threshold]
    @memberships = @memberships.order('created_at desc')
    erb :'members/members'
  end   
  
  get '/h/:slug/join' do      
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    redirect "/h/#{@group.slug}/apply" if @group.enable_applications
    @title = "#{@group.name} · #{ENV['SITE_TITLE']}"
    @og_desc = "#{@group.name} is being co-created on #{ENV['SITE_TITLE']}"
    @og_image = @group.cover_image ? @group.cover_image.url : ENV['SITE_IMAGE']
    @account = Account.new
    erb :'members/join'
  end  	  
  
  post '/h/:slug/join' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    halt if @group.enable_applications
    
    if current_account
      @account = current_account
    else           
      redirect back unless params[:account] and params[:account][:email]
      if !(@account = Account.find_by(email: /^#{::Regexp.escape(params[:account][:email])}$/i))
        @account = Account.new(mass_assigning(params[:account], Account))
        @account.password = Account.generate_password(8) # not used
        if !@account.save
          flash[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
          redirect back
        end
      end
    end    
    
    if @group.memberships.find_by(account: @account)
      flash[:notice] = "You're already part of that group"
      redirect back
    else
      @group.memberships.create! account: @account
      session[:account_id] = @account.id.to_s
      redirect "/h/#{@group.slug}"
    end    
  end  
  
  get '/h/:slug/leave' do  
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!    
    flash[:notice] = "You left #{@group.name}"
    @membership.destroy
    redirect '/'
  end
  
  post '/h/:slug/add_member' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only! 
      
    if !params[:email] or !params[:name]
      flash[:error] = "Please provide a name and email address"
      redirect back        
    end
            
    if !(@account = Account.find_by(email: /^#{::Regexp.escape(params[:email])}$/i))
      @account = Account.new(name: params[:name], email: params[:email], password: Account.generate_password(8))
      if !@account.save
        flash[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
        redirect back
      end
    end
      
    if @group.memberships.find_by(account: @account)
      flash[:notice] = "That person is already a member of the group"
      redirect back
    else
      @group.memberships.create! account: @account, prevent_notifications: params[:prevent_notifications], added_by: current_account
      redirect back
    end       
        
  end
            
  get '/memberships/:id/make_admin' do
    membership = Membership.find(params[:id]) || not_found
    @group = membership.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    membership.admin = true
    membership.admin_status_changed_by = current_account
    membership.save!
    membership.notifications.where(:type.in => ['made_admin', 'unadmined']).destroy_all
    membership.notifications.create! :group => @group, :type => 'made_admin'
    redirect back      
  end
    
  get '/memberships/:id/unadmin' do
    membership = Membership.find(params[:id]) || not_found
    @group = membership.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    membership.admin = false
    membership.admin_status_changed_by = current_account
    membership.save!
    membership.notifications.where(:type.in => ['made_admin', 'unadmined']).destroy_all
    membership.notifications.create! :group => @group, :type => 'unadmined'
    redirect back      
  end    
    
  get '/memberships/:id/remove' do
    membership = Membership.find(params[:id]) || not_found
    @group = membership.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    membership.destroy
    redirect back      
  end    
        
  post '/memberships/:id/paid' do
    membership = Membership.find(params[:id]) || not_found
    @group = membership.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    membership.paid = params[:paid]
    membership.save
    200
  end  
      
  post '/memberships/:id/tier' do
    membership = Membership.find(params[:id]) || not_found
    @group = membership.group
    @membership = @group.memberships.find_by(account: current_account)
    (membership.id == @membership.id) or group_admins_only!
    @group.tierships.find_by(account: membership.account_id).try(:destroy)
    @group.tierships.create(account: membership.account_id, tier_id: params[:tier_id])
    200
  end    
      
  post '/memberships/:id/accom' do
    membership = Membership.find(params[:id]) || not_found
    @group = membership.group
    @membership = @group.memberships.find_by(account: current_account)
    (membership.id == @membership.id) or group_admins_only!
    @group.accomships.find_by(account: membership.account_id).try(:destroy)
    @group.accomships.create(account: membership.account_id, accom_id: params[:accom_id])
    200
  end   
      
  post '/memberships/:id/booking_limit' do
    membership = Membership.find(params[:id]) || not_found
    @group = membership.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    membership.update_attribute(:booking_limit, params[:booking_limit])
    200
  end   
  
  get '/membership_row/:id' do
    membership = Membership.find(params[:id]) || not_found
    @group = membership.group
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    partial :'members/membership_row', :locals => {:membership => membership}
  end    
  
  get '/h/:slug/compare' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only! 
    erb :'members/compare'
  end  
  
  post '/h/:slug/update_facebook_names' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only! 
    params[:facebook_names].each { |k,v|
      @group.memberships.find_by(account_id: k).account.update_attribute(:facebook_name, v)
    }
    redirect back
  end
  
end