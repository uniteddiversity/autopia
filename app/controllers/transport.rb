Huddl::App.controller do

  get '/h/:slug/transports' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @transport = Transport.new
    erb :'transports/transports'
  end
  
  post '/h/:slug/transports/new' do
    @group = Group.find_by(slug: params[:slug])  || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @transport = @group.transports.new(params[:transport])
    @transport.cost = 0 unless @membership.admin?
    @transport.account = current_account
    if @transport.save
      redirect back
    else
      erb :'transports/build'
    end
  end    
  
  get '/h/:slug/transports/:id/edit' do
    @group = Group.find_by(slug: params[:slug])  || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @transport = @group.transports.find(params[:id]) || not_found
    erb :'transports/build'     
  end  
  
  post '/h/:slug/transports/:id/edit' do
    @group = Group.find_by(slug: params[:slug])  || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @transport = @group.transports.find(params[:id]) || not_found
    if @transport.update_attributes(params[:transport])
      redirect "/h/#{@group.slug}/transports"
    else
      erb :'transports/build'
    end
  end   

  get '/h/:slug/transports/:id/destroy' do
    @group = Group.find_by(slug: params[:slug])  || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @transport = @group.transports.find(params[:id]) || not_found
    @transport.destroy   
    redirect "/h/#{@group.slug}/transports"
  end  
    
  get '/transportships/create' do
    @transport = Transport.find(params[:transport_id]) || not_found
    @group = @transport.group      
    membership_required!      
    Transportship.create(account: current_account, transport_id: params[:transport_id], group: @group)
    redirect back
  end    
    
  get '/transportships/:id/destroy' do
    @transportship = Transportship.find(params[:id]) || not_found
    @group = @transportship.transport.group
    @membership = @group.memberships.find_by(account: current_account)
    halt unless @transportship.account.id == current_account.id or @membership.admin?
    @transportship.destroy
    redirect back
  end 
    
end