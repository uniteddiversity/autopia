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
      redirect "/h/#{@group.slug}"
    else
      flash.now[:error] = 'Some errors prevented the group from being created'
      erb :build
    end
  end
  
  get '/h/:slug' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    @notifications = @group.notifications.order('created_at desc').page(params[:page])
    membership_required!
    if request.xhr?
      partial :newsfeed, :locals => {:notifications => @notifications}   
    else
      erb :group
    end
  end    
  
  get '/h/:slug/todos' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    partial :todos
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
    
  post '/groups/:slug/upload_picture/:account_id' do
    @group = Group.find_by(slug: params[:slug]) || not_found      
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    halt unless (@group.memberships.find_by(account_id: params[:account_id]) or @group.mapplications.find_by(account_id: params[:account_id]))
    Account.find(params[:account_id]).update_attribute(:picture, params[:upload])
    redirect back
  end
    
end