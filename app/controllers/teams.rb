Autopia::App.controller do
  
  get '/a/:slug/teams/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = Team.new
    erb :'teams/build', :layout => 'layouts/teams' 
  end
  
  post '/a/:slug/teams/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = @group.teams.build(params[:team])
    @team.account = current_account
    if @team.save
      @team.teamships.create(account: current_account)
      redirect "/a/#{@group.slug}/teams/#{@team.id}"
    else
      erb :'teams/build', :layout => 'layouts/teams' 
    end
  end
  
  get '/a/:slug/teams' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    if request.xhr?
      partial :'teams/teams'
    else
      erb :'teams/teams'
    end
  end
  
  get '/a/:slug/teams/:id' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = @group.teams.find(params[:id])    
    if request.xhr?
      partial :'teams/team'
    else
      erb :'teams/team', :layout => 'layouts/teams' 
    end
  end
  
  get '/a/:slug/teams/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = @group.teams.find(params[:id])
    erb :'teams/build', :layout => 'layouts/teams' 
  end  
  
  post '/a/:slug/teams/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = @group.teams.find(params[:id])
    if @team.update_attributes(params[:team])
      redirect "/a/#{@group.slug}/teams/#{@team.id}"
    else
      erb :'teams/build', :layout => 'layouts/teams' 
    end
  end    
  
  get '/a/:slug/teams/:id/destroy' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = @group.teams.find(params[:id])
    @team.destroy
    redirect "/a/#{@group.slug}/teams"
  end    
                   
  get '/teamships/create' do
    @team = Team.find(params[:team_id]) || not_found
    @group = @team.group      
    confirmed_membership_required!      
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
  
  get '/teamships/:id/subscribe' do
    @teamship = Teamship.find(params[:id]) || not_found
    @team = @teamship.team
    @group = @teamship.team.group
    @membership = @group.memberships.find_by(account: current_account)
    halt unless @teamship.account.id == current_account.id or @membership.admin?
    @teamship.update_attribute(:unsubscribed, nil)
    flash[:notice] = "You'll now receive email notifications of new posts in #{@team.name}"
    redirect "/a/#{@group.slug}/teams/#{@team.id}"
  end
  
  get '/a/:slug/teams/:id/unsubscribe' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = @group.teams.find(params[:id])
    @teamship = @team.teamships.find_by(account: current_account)
    redirect (@teamship ? "/teamships/#{@teamship.id}/unsubscribe" : "/a/#{@group.slug}/teams/#{@team.id}")
  end

  get '/teamships/:id/unsubscribe' do
    @teamship = Teamship.find(params[:id]) || not_found
    @team = @teamship.team
    @group = @teamship.team.group
    @membership = @group.memberships.find_by(account: current_account)
    halt unless @teamship.account.id == current_account.id or @membership.admin?    
    @teamship.update_attribute(:unsubscribed, true)
    @team.subscriptions.where(account: current_account).destroy_all
    flash[:notice] = "OK! You won't receive emails about #{@team.name}"
    redirect "/a/#{@group.slug}/teams/#{@team.id}"
  end
     
end