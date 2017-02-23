ActivateApp::App.controller do
  
  get '/h/:slug/teams' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    erb :teams      
  end
           
  post '/teams/create' do
    @group = Group.find(params[:group_id])  || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    Team.create(name: params[:name], group: @group, account: current_account)
    redirect back
  end
    
  get '/teams/:id/destroy' do
    @team = Team.find(params[:id]) || not_found
    @group = @team.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @team.destroy
    redirect back      
  end
        
  get '/teamships/create' do
    @team = Team.find(params[:team_id]) || not_found
    @group = @team.group      
    membership_required!      
    Teamship.create(account: current_account, team_id: params[:team_id])
    redirect back
  end    
    
  get '/teamships/:id/destroy' do
    @teamship = Teamship.find(params[:id]) || not_found
    @group = @teamship.team.group
    @membership = @group.memberships.find_by(account: current_account)
    halt unless @teamship.account.id == current_account.id or @membership.admin?
    @teamship.destroy
    redirect back
  end  
  
end