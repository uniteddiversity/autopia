Huddl::App.controller do
    
  get '/h/new' do
    sign_in_required!
    @group = Group.new
    Group.enablable.each { |x|
      @group.send("enable_#{x}=", true)
    }
    @group.enable_bookings = false
    erb :'groups/build'
  end  
    
  post '/h/new' do
    sign_in_required!
    @group = Group.new(params[:group])
    @group.account = current_account
    if @group.save
      redirect "/h/#{@group.slug}"
    else
      flash.now[:error] = 'Some errors prevented the group from being created'
      erb :'groups/build'
    end
  end
  
  get '/h/:slug' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    if !@membership
      if @group.enable_applications
        redirect "/h/#{@group.slug}/apply"
      else
        redirect "/h/#{@group.slug}/join"
      end
    end
    erb :'groups/group'
  end  
  
  get '/h/:slug/newsfeed' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    confirmed_membership_required!
    @notifications = @group.notifications.order('created_at desc').page(params[:page])
    partial :'groups/newsfeed', :locals => {:notifications => @notifications}   
  end
  
  get '/h/:slug/minifeed' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)        
    confirmed_membership_required!
    @notifications = @group.notifications.order('created_at desc').limit(3)
    partial :'groups/newsfeed', :locals => {:notifications => @notifications, :minifeed => true}
  end
  
  get '/h/:slug/todos' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    partial :'groups/todos'
  end   
      
  get '/h/:slug/edit' do        
    @group = Group.find_by(slug: params[:slug]) || not_found      
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    erb :'groups/build'
  end  
    
  post '/h/:slug/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found      
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    if @group.update_attributes(params[:group])
      redirect "/h/#{@group.slug}"
    else
      flash.now[:error] = 'Some errors prevented the group from being created'
      erb :'groups/build'        
    end
  end
  
  get '/h/:slug/destroy' do        
    @group = Group.find_by(slug: params[:slug]) || not_found      
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @group.destroy
    flash[:notice] = 'The group was deleted'
    redirect '/'
  end   
  
  get '/h/:slug/subscribe' do        
    @group = Group.find_by(slug: params[:slug]) || not_found      
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @membership.update_attribute(:unsubscribed, nil)
    flash[:notice] = "You'll now receive email notifications of key events in #{@group.name}"
    redirect "/h/#{@group.slug}"
  end      
  
  get '/h/:slug/unsubscribe' do        
    @group = Group.find_by(slug: params[:slug]) || not_found      
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @membership.update_attribute(:unsubscribed, true)
    flash[:notice] = "OK! You won't receive emails about key events in #{@group.name}"
    redirect "/h/#{@group.slug}"
  end      
        
end