ActivateApp::App.controller do
 
  get '/h/:slug/tiers' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    erb :tiers
  end
    
  post '/tiers/create' do
    @group = Group.find(params[:group_id])  || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    Tier.create(name: params[:name], cost: params[:cost], description: params[:description], group: @group, account: current_account)
    redirect back
  end    

  get '/tiers/:id/destroy' do
    @tier = Tier.find(params[:id]) || not_found
    @group = @tier.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @tier.destroy
    redirect back      
  end
    
  get '/tierships/create' do
    @tier = Tier.find(params[:tier_id]) || not_found
    @group = @tier.group      
    membership_required!      
    Tiership.create(account: current_account, tier_id: params[:tier_id], group: @group)
    redirect back
  end    
    
  get '/tierships/:id/destroy' do
    @tiership = Tiership.find(params[:id]) || not_found
    @group = @tiership.tier.group
    @membership = @group.memberships.find_by(account: current_account)
    halt unless @tiership.account.id == current_account.id or @membership.admin?
    @tiership.destroy
    redirect back
  end       
    
end