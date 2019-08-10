Autopia::App.controller do

  get '/a/:slug/budget' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @spend = Spend.new
    if request.xhr?
      partial :'budget/budget'
    else
      discuss 'Budget'
      erb :'budget/budget'
    end
  end

  post '/a/:slug/spends/new' do
    @gathering = Gathering.find_by(slug: params[:slug])  || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @spend = @gathering.spends.new(params[:spend])
    @spend.account = current_account unless @membership.admin?
    if @spend.save
      redirect back
    else
      erb :'budget/build'
    end
  end    
  
  get '/a/:slug/spends/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug])  || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @spend = @gathering.spends.find(params[:id]) || not_found
    erb :'budget/build'     
  end  
  
  post '/a/:slug/spends/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug])  || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @spend = @gathering.spends.find(params[:id]) || not_found
    if @spend.update_attributes(params[:spend])
      redirect "/a/#{@gathering.slug}/budget"
    else
      erb :'budget/build'
    end
  end   

  get '/a/:slug/spends/:id/destroy' do
    @gathering = Gathering.find_by(slug: params[:slug])  || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @spend = @gathering.spends.find(params[:id]) || not_found
    @spend.destroy   
    redirect "/a/#{@gathering.slug}/budget"
  end     
      
  post '/spends/:id/reimbursed' do
    @spend = Spend.find(params[:id]) || not_found
    @gathering = @spend.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @spend.update_attribute(:reimbursed, params[:reimbursed])
    200  
  end      
        
  post '/teams/:id/budget' do
    @team = Team.find(params[:id]) || not_found
    @gathering = @team.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required! 
    @team.update_attribute(:budget, params[:budget])
    200  
  end
  
end