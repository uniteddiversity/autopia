Huddl::App.controller do

  get '/h/:slug/spending' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    erb :spending
  end

  post '/spends/create' do
    @group = Group.find(params[:group_id]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    Spend.create(item: params[:item], amount: params[:amount], account: current_account, group: @group)
    redirect back
  end
    
  get '/spends/:id/destroy' do
    @spend = Spend.find(params[:id]) || not_found
    @group = @spend.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @spend.destroy
    redirect back      
  end     
    
  get '/spends/:id/reimbursed' do
    @spend = Spend.find(params[:id]) || not_found
    @group = @spend.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @spend.update_attribute(:reimbursed, true)
    redirect back      
  end      
    
end