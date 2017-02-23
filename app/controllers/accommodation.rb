Huddl::App.controller do
  
  get '/h/:slug/accoms' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    erb :accoms
  end
    
  post '/accoms/create' do
    @group = Group.find(params[:group_id])  || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    Accom.create(name: params[:name], cost: params[:cost], description: params[:description], capacity: params[:capacity], group: @group, account: current_account)
    redirect back
  end    

  get '/accoms/:id/destroy' do
    @accom = Accom.find(params[:id]) || not_found
    @group = @accom.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @accom.destroy
    redirect back      
  end
    
  get '/accomships/create' do
    @accom = Accom.find(params[:accom_id]) || not_found
    @group = @accom.group      
    membership_required!      
    Accomship.create(account: current_account, accom_id: params[:accom_id], group: @group)
    redirect back
  end    
    
  get '/accomships/:id/destroy' do
    @accomship = Accomship.find(params[:id]) || not_found
    @group = @accomship.accom.group
    @membership = @group.memberships.find_by(account: current_account)
    halt unless @accomship.account.id == current_account.id or @membership.admin?
    @accomship.destroy
    redirect back
  end        
  
end