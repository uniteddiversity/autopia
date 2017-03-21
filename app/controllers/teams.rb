Huddl::App.controller do
  
  get '/h/:slug/teams/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @team = Team.new
    erb :team_build, :layout => 'layouts/teams'   
  end
  
  post '/h/:slug/teams/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @team = @group.teams.build(params[:team])
    @team.account = current_account
    if @team.save
      redirect "/h/#{@group.slug}/teams/#{@team.id}"
    else
      erb :team_build, :layout => 'layouts/teams'   
    end
  end
  
  get '/h/:slug/teams' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    erb :teams, :layout => 'layouts/teams'      
  end
  
  get '/h/:slug/teams/:id' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @team = @group.teams.find(params[:id])
    @comment = @team.comments.build
    erb :team, :layout => 'layouts/teams'
  end
  
  post '/h/:slug/teams/:id/comment' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @team = @group.teams.find(params[:id])    
    @comment = @team.comments.build(params[:comment])
    @comment.account = current_account
    if @comment.save
      redirect back
    else
      flash[:error] = 'There was an error saving the comment'
      erb :team
    end
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