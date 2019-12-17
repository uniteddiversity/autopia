Autopia::App.controller do
  
  get '/a/:slug/teams/new' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = Team.new
    erb :'teams/build'
  end
  
  post '/a/:slug/teams/new' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = @gathering.teams.build(params[:team])
    @team.account = current_account
    if @team.save
      @team.teamships.create(account: current_account)
      redirect "/a/#{@gathering.slug}/teams/#{@team.id}"
    else
      erb :'teams/build'
    end
  end
  
  get '/a/:slug/teams' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    if request.xhr?
      partial :'teams/teams'
    else
      discuss 'Teams'
      erb :'teams/teams'
    end
  end
  
  get '/a/:slug/teams/:id' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = @gathering.teams.find(params[:id]) || not_found    
    if request.xhr?
      partial :'teams/team'
    else
      discuss 'Teams'
      erb :'teams/team', :layout => 'layouts/teams' 
    end
  end
  
  get '/a/:slug/teams/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = @gathering.teams.find(params[:id]) || not_found
    erb :'teams/build'
  end  
  
  post '/a/:slug/teams/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = @gathering.teams.find(params[:id]) || not_found
    if @team.update_attributes(mass_assigning(params[:team], Team))
      redirect "/a/#{@gathering.slug}/teams/#{@team.id}"
    else
      erb :'teams/build' 
    end
  end    
  
  get '/a/:slug/teams/:id/destroy' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = @gathering.teams.find(params[:id]) || not_found
    @team.destroy
    redirect "/a/#{@gathering.slug}/teams"
  end    
                   
  get '/teamships/create' do
    @team = Team.find(params[:team_id]) || not_found
    @gathering = @team.gathering      
    confirmed_membership_required!      
    Teamship.create(account: current_account, team_id: params[:team_id])
    redirect back
  end    
    
  get '/teamships/:id/destroy' do
    @teamship = Teamship.find(params[:id]) || not_found
    @gathering = @teamship.team.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    halt unless @teamship.account.id == current_account.id or @membership.admin?
    @teamship.destroy
    redirect back
  end  
  
  get '/teamships/:id/subscribe' do
    @teamship = Teamship.find(params[:id]) || not_found
    @team = @teamship.team
    @gathering = @teamship.team.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    halt unless @teamship.account.id == current_account.id or @membership.admin?
    @teamship.update_attribute(:unsubscribed, nil)
    flash[:notice] = "You'll now receive email notifications of new posts in #{@team.name}"
    redirect "/a/#{@gathering.slug}/teams/#{@team.id}"
  end
  
  get '/a/:slug/teams/:id/unsubscribe' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @team = @gathering.teams.find(params[:id]) || not_found
    @teamship = @team.teamships.find_by(account: current_account)
    redirect (@teamship ? "/teamships/#{@teamship.id}/unsubscribe" : "/a/#{@gathering.slug}/teams/#{@team.id}")
  end

  get '/teamships/:id/unsubscribe' do
    @teamship = Teamship.find(params[:id]) || not_found
    @team = @teamship.team
    @gathering = @teamship.team.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    halt unless @teamship.account.id == current_account.id or @membership.admin?    
    @teamship.update_attribute(:unsubscribed, true)
    @team.subscriptions.where(account: current_account).destroy_all
    flash[:notice] = "OK! You won't receive emails about #{@team.name}"
    redirect "/a/#{@gathering.slug}/teams/#{@team.id}"
  end
     
end