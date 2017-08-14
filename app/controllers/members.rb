Huddl::App.controller do
  
	get '/h/:slug/members' do        
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @memberships = @group.memberships
    @memberships = @memberships.where(:account_id.in => Account.where(gender: params[:gender]).pluck(:id)) if params[:gender]
    @memberships = @memberships.where(:account_id.in => Account.where(poc: true).pluck(:id)) if params[:poc]      
    @memberships = @memberships.where(:account_id.in => Account.where(:date_of_birth.lte => (Date.today-params[:p].to_i.years)).where(:date_of_birth.gt => (Date.today-(params[:p].to_i+10).years)).pluck(:id)) if params[:p]      
    @memberships = @memberships.where(:account_id.in => Account.where(name: /#{Regexp.escape(params[:q])}/i).pluck(:id)) if params[:q]
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
  
  post '/h/:slug/add_member' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only! 
      
    if !params[:email] or !params[:name]
      flash[:error] = "Please provide a name and email address"
      redirect back        
    end
            
    if !(@account = Account.find_by(email: /^#{Regexp.escape(params[:email])}$/i))
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
      @group.memberships.create! account: @account, added_by: current_account
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
    membership_required!
    partial :'members/membership_row', :locals => {:membership => membership}
  end     

  get '/update_facebook_name/:id' do
    halt unless current_account and current_account.admin?
    account = Account.find(params[:id]) || not_found
    partial :'members/update_facebook_name', :locals => {:account => account}
  end    
  
  post '/update_facebook_name/:id' do
    halt unless current_account and current_account.admin?
    Account.find(params[:id]).update_attribute(:facebook_name, params[:facebook_name])
    200
  end  
  
end