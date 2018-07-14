Autopoetica::App.controller do
    
  post '/h/:slug/tiers/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!    
    @tier = @group.tiers.build(params[:tier])
    @tier.account = current_account
    if @tier.save
      redirect "/h/#{@group.slug}/tiers"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the tier from being saved."
      erb :'tiers/build'    
    end
  end  
 
  get '/h/:slug/tiers' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    if request.xhr?
      partial :'tiers/tiers'
    else
      erb :'tiers/tiers'
    end
  end
  
  get '/h/:slug/tiers/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!    
    @tier = @group.tiers.find(params[:id])
    erb :'tiers/build'
  end
  
  post '/h/:slug/tiers/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!    
    @tier = @group.tiers.find(params[:id])
    if @tier.update_attributes(params[:tier])
      redirect "/h/#{@group.slug}/tiers"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the tier from being saved." 
      erb :'tiers/build'
    end
  end  
  
  get '/h/:slug/tiers/:id/destroy' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!    
    @tier = @group.tiers.find(params[:id])
    @tier.destroy
    redirect "/h/#{@group.slug}/tiers"      
  end     
        
  get '/tierships/create' do
    @tier = Tier.find(params[:tier_id]) || not_found
    @group = @tier.group      
    confirmed_membership_required!      
    Tiership.create(account: current_account, tier_id: params[:tier_id], group: @group)
    200
  end    
    
  get '/tierships/:id/destroy' do
    @tiership = Tiership.find(params[:id]) || not_found
    @group = @tiership.tier.group
    @membership = @group.memberships.find_by(account: current_account)
    halt unless @tiership.account.id == current_account.id or @membership.admin?
    @tiership.destroy
    200
  end       
    
end