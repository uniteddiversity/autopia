ActivateApp::App.controller do

  get '/h/:slug/transports' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    erb :transports
  end
    
  post '/transports/create' do
    @group = Group.find(params[:group_id])  || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    Transport.create(name: params[:name], cost: (@membership.admin? ? params[:cost] : 0), capacity: params[:capacity], description: params[:description], group: @group, account: current_account)
    redirect back
  end    

  get '/transports/:id/destroy' do
    @transport = Transport.find(params[:id]) || not_found
    @group = @transport.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @transport.destroy
    redirect back      
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