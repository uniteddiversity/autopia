Autopia::App.controller do
  
	get '/a/:slug/members', :provides => [:html, :csv] do        
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @memberships = @gathering.memberships    
    @gathering.radio_scopes.select { |k,v,t,r| params[k] == v.to_s && params[k] != 'all' }.each { |k,v,t,r|
      @memberships = @memberships.where(:id.in => r.pluck(:id))
    }    
    @gathering.check_box_scopes.select { |k,t,r| params[k] }.each { |k,t,r|
      @memberships = @memberships.where(:id.in => r.pluck(:id))
    }       
    @memberships = @memberships.where(:account_id.in => Account.where(name: /#{::Regexp.escape(params[:q])}/i).pluck(:id)) if params[:q]
    @memberships = @memberships.order('created_at desc')
    case content_type
    when :html        
      discuss 'Members'
      erb :'members/members'
    when :csv
      CSV.generate do |csv|
        csv << %w{name email joined}
        @memberships.each { |membership| csv << [membership.account.name, membership.account.email, membership.created_at.to_s(:db)] }        
      end        
    end
  end   
  
  get '/a/:slug/join' do      
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)    
    redirect "/a/#{@gathering.slug}/apply" unless @gathering.privacy == 'open'
    @og_desc = "#{@gathering.name} is being co-created on Autopia"
    @og_image = @gathering.cover_image ? @gathering.cover_image.url : "#{ENV['BASE_URI']}/images/autopia-link.png"
    @account = Account.new
    erb :'members/join'
  end  	  
  
  post '/a/:slug/join' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    halt unless @gathering.privacy == 'open'
    
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
    
    if @gathering.memberships.find_by(account: @account)
      flash[:notice] = "You're already part of that gathering"
      redirect back
    else
      @gathering.memberships.create! account: @account
      session[:account_id] = @account.id.to_s
      redirect "/a/#{@gathering.slug}"
    end    
  end  
  
  get '/a/:slug/leave' do  
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!    
    flash[:notice] = "You left #{@gathering.name}"
    @membership.destroy
    redirect '/'
  end
  
  post '/a/:slug/add_member' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required! 
    
    if !@membership.admin? && @membership.invitations_remaining == 0
      flash[:error] = "You have run out of invitations"
      redirect back
    end
      
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
      
    if @gathering.memberships.find_by(account: @account)
      flash[:notice] = "That person is already a member of the gathering"
      redirect back
    else
      @gathering.memberships.create! account: @account, prevent_notifications: params[:prevent_notifications], added_by: current_account      
      redirect back
    end       
        
  end
            
  get '/memberships/:id/make_admin' do
    membership = Membership.find(params[:id]) || not_found
    @gathering = membership.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    membership.admin = true
    membership.admin_status_changed_by = current_account
    membership.save!
    membership.notifications.where(:type.in => ['made_admin', 'unadmined']).destroy_all
    membership.notifications.create! :circle => @gathering, :type => 'made_admin'
    redirect back      
  end
    
  get '/memberships/:id/unadmin' do
    membership = Membership.find(params[:id]) || not_found
    @gathering = membership.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    membership.admin = false
    membership.admin_status_changed_by = current_account
    membership.save!
    membership.notifications.where(:type.in => ['made_admin', 'unadmined']).destroy_all
    membership.notifications.create! :circle => @gathering, :type => 'unadmined'
    redirect back      
  end    
    
  get '/memberships/:id/remove' do
    membership = Membership.find(params[:id]) || not_found
    @gathering = membership.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    membership.destroy
    redirect back      
  end    
        
  post '/memberships/:id/paid' do
    membership = Membership.find(params[:id]) || not_found
    @gathering = membership.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    membership.paid = params[:paid]
    membership.save
    200
  end  
      
  post '/memberships/:id/tier' do
    membership = Membership.find(params[:id]) || not_found
    @gathering = membership.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    (membership.id == @membership.id) or gathering_admins_only!
    @gathering.tierships.find_by(account: membership.account_id).try(:destroy)
    @gathering.tierships.create(account: membership.account_id, tier_id: params[:tier_id])
    200
  end    
      
  post '/memberships/:id/accom' do
    membership = Membership.find(params[:id]) || not_found
    @gathering = membership.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    (membership.id == @membership.id) or gathering_admins_only!
    @gathering.accomships.find_by(account: membership.account_id).try(:destroy)
    @gathering.accomships.create(account: membership.account_id, accom_id: params[:accom_id])
    200
  end   
            
  post '/memberships/:id/member_of_facebook_group' do
    membership = Membership.find(params[:id]) || not_found
    @gathering = membership.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    membership.update_attribute(:member_of_facebook_group, params[:member_of_facebook_group])
    200  
  end   
  
  get '/membership_row/:id' do
    membership = Membership.find(params[:id]) || not_found
    @gathering = membership.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    partial :'members/membership_row', :locals => {:membership => membership}
  end    
   
end