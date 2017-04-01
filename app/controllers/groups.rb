Huddl::App.controller do

  get '/h/new' do
    sign_in_required!
    @group = Group.new
    Group.enablable.each { |x|
      @group.send("enable_#{x}=", true)
    }
    @group.enable_bookings = false
    erb :build
  end  
    
  post '/h/new' do
    sign_in_required!
    @group = Group.new(params[:group])
    @group.account = current_account
    if @group.save
      @group.memberships.create! account: current_account, admin: true
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
    @memberships = @memberships.where('this.requested_contribution == this.paid') if params[:paid]
    @memberships = @memberships.where('this.requested_contribution > this.paid') if params[:more_to_pay]
    @memberships = @memberships.where(:paid => 0) if params[:paid_nothing]
    @memberships = @memberships.where(:account_id.in => @group.shifts.pluck(:account_id)) if params[:shifts]
    @memberships = @memberships.where(:account_id.nin => @group.shifts.pluck(:account_id)) if params[:no_shifts]      
    @memberships = @memberships.where(:account_id.nin => @group.tierships.pluck(:account_id)) if params[:no_tier]     
    @memberships = @memberships.where(:account_id.nin => @group.accomships.pluck(:account_id)) if params[:no_accom]     
    @memberships = @memberships.where(:desired_threshold.ne => nil) if params[:threshold]
    @memberships = @memberships.order('created_at desc')
    erb :'members/members'
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
    
  get '/h/:slug/newsfeed' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @notifications = @group.notifications.order('created_at desc').page(params[:page])
    erb :newsfeed
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