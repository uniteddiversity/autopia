Huddl::App.controller do

  get '/h/:slug/budget' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @spend = Spend.new
    erb :'budget/budget'
  end

  post '/h/:slug/spends/new' do
    @group = Group.find_by(slug: params[:slug])  || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @spend = @group.spends.new(params[:spend])
    @spend.account = current_account
    if @spend.save
      redirect back
    else
      erb :'budget/build'
    end
  end    
  
  get '/h/:slug/spends/:id/edit' do
    @group = Group.find_by(slug: params[:slug])  || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @spend = @group.spends.find(params[:id]) || not_found
    erb :'budget/build'     
  end  
  
  post '/h/:slug/spends/:id/edit' do
    @group = Group.find_by(slug: params[:slug])  || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @spend = @group.spends.find(params[:id]) || not_found
    if @spend.update_attributes(params[:spend])
      redirect "/h/#{@group.slug}/budget"
    else
      erb :'budget/build'
    end
  end   

  get '/h/:slug/spends/:id/destroy' do
    @group = Group.find_by(slug: params[:slug])  || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @spend = @group.spends.find(params[:id]) || not_found
    @spend.destroy   
    redirect "/h/#{@group.slug}/budget"
  end     
  
  get '/spends/:id/reimbursed' do
    @spend = Spend.find(params[:id]) || not_found
    @group = @spend.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    partial :'budget/reimbursed', :locals => {:spend => @spend}
  end
    
  post '/spends/:id/reimbursed' do
    @spend = Spend.find(params[:id]) || not_found
    @group = @spend.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @spend.update_attribute(:reimbursed, params[:reimbursed])
    200  
  end      
    
end