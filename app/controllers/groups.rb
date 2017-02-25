Huddl::App.controller do

  get '/h/new' do
    sign_in_required!
    @group = Group.new
    Group.enablable.each { |x|
      @group.send("enable_#{x}=", true)
    }
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
    @memberships = @group.memberships
    @memberships = @memberships.where(:account_id.in => Account.where(gender: params[:gender]).pluck(:id)) if params[:gender]
    @memberships = @memberships.where(:account_id.in => Account.where(poc: true).pluck(:id)) if params[:poc]      
    @memberships = @memberships.where(:account_id.in => Account.where(:date_of_birth.lte => (Date.today-params[:p].to_i.years)).where(:date_of_birth.gt => (Date.today-(params[:p].to_i+10).years)).pluck(:id)) if params[:p]      
    @memberships = @memberships.where(:account_id.in => Account.where(name: /#{Regexp.escape(params[:q])}/i).pluck(:id)) if params[:q]
    @memberships = @memberships.where(:paid.ne => nil) if params[:paid]
    @memberships = @memberships.where(:paid => nil) if params[:not_paid]
    @memberships = @memberships.where(:account_id.in => @group.shifts.pluck(:account_id)) if params[:shifts]
    @memberships = @memberships.where(:account_id.nin => @group.shifts.pluck(:account_id)) if params[:no_shifts]      
    @memberships = @memberships.where(:added_to_facebook_group => true) if params[:facebook]
    @memberships = @memberships.where(:added_to_facebook_group.ne => true) if params[:not_facebook]     
    @memberships = @memberships.where(:desired_threshold.ne => nil) if params[:threshold]
    @memberships = @memberships.where(:desired_threshold => nil) if params[:no_threshold]      
    @memberships = @memberships.order('created_at desc')
    erb :members
  end
    
  get '/h/:slug/newsfeed' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @notifications = @group.notifications.order('created_at desc').page(params[:page])
    erb :newsfeed
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
      membership = @group.memberships.create! account: @account, added_by: current_account
      redirect back
    end       
        
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
      @mapplication = @group.mapplications.create! :account => @account, :status => 'pending', :answers => (params[:answers].map { |i,x| [@group.application_questions_a[i.to_i],x] } if params[:answers])
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
    
  get '/h/:slug/threshold' do     
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    partial :threshold
  end     
    
  post '/h/:slug/threshold' do     
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    @membership.desired_threshold = params[:desired_threshold]
    @membership.save!
    200
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
    Verdict.create(account: current_account, mapplication_id: params[:mapplication_id], type: params[:type], reason: params[:reason])
    200
  end       
    
  get '/verdicts/:id/destroy' do
    @verdict = Verdict.find(params[:id]) || not_found
    halt unless @verdict.account.id == current_account.id
    @verdict.destroy
    200
  end     
  
  get '/mapplications/:id/process' do
    @mapplication = Mapplication.find(params[:id]) || not_found
    @group = @mapplication.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @mapplication.status = params[:status]
    @mapplication.processed_by = current_account
    @mapplication.save!
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
    partial :added_to_facebook_group, :locals => {:membership => membership}
  end    
    
  post '/memberships/:id/added_to_facebook_group' do
    membership = Membership.find(params[:id]) || not_found
    @group = membership.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    membership.update_attribute(:added_to_facebook_group, true)
    200
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
    
  get '/memberships/:id/paid' do
    membership = Membership.find(params[:id]) || not_found
    @group = membership.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    partial :paid, :locals => {:membership => membership}      
  end
    
  post '/memberships/:id/paid' do
    membership = Membership.find(params[:id]) || not_found
    @group = membership.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    membership.update_attribute(:paid, params[:paid])
    200
  end  
  
  get '/mapplications/:id' do
    @mapplication = Mapplication.find(params[:id]) || not_found
    @group = @mapplication.group
    @membership = @group.memberships.find_by(account: current_account)      
    membership_required!
    partial :mapplication, :object => @mapplication
  end
    
  get '/mapplication_row/:id' do
    @mapplication = Mapplication.find(params[:id]) || not_found
    @group = @mapplication.group
    @membership = @group.memberships.find_by(account: current_account)      
    membership_required!
    if @mapplication.status == 'accepted'
      200
    else
      partial :mapplication_row, :locals => {:mapplication => @mapplication}
    end
  end    

  post '/groups/:slug/upload_picture/:account_id' do
    @group = Group.find_by(slug: params[:slug]) || not_found      
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    halt unless (@group.memberships.find_by(account_id: params[:account_id]) or @group.mapplications.find_by(account_id: params[:account_id]))
    Account.find(params[:account_id]).update_attribute(:picture, params[:upload])
    redirect back
  end
    
end