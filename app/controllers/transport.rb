Autopia::App.controller do

  get '/a/:slug/transports' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @transport = Transport.new
    @transport.cost = 0 unless @membership.admin?
    if request.xhr?
      partial :'transports/transports'
    else
      discuss 'Transport'
      erb :'transports/transports'
    end
  end
  
  post '/a/:slug/transports/new' do
    @gathering = Gathering.find_by(slug: params[:slug])  || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @transport = @gathering.transports.new(mass_assigning(params[:transport], Transport))
    @transport.cost = 0 unless @membership.admin?
    @transport.account = current_account
    if @transport.save
      redirect back
    else
      erb :'transports/build'
    end
  end    
  
  get '/a/:slug/transports/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug])  || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @transport = @gathering.transports.find(params[:id]) || not_found
    erb :'transports/build'     
  end  
  
  post '/a/:slug/transports/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug])  || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @transport = @gathering.transports.find(params[:id]) || not_found
    if @transport.update_attributes(mass_assigning(params[:transport], Transport))
      redirect "/a/#{@gathering.slug}/transports"
    else
      erb :'transports/build'
    end
  end   

  get '/a/:slug/transports/:id/destroy' do
    @gathering = Gathering.find_by(slug: params[:slug])  || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    @transport = @gathering.transports.find(params[:id]) || not_found
    @transport.destroy   
    redirect "/a/#{@gathering.slug}/transports"
  end  
    
  get '/transportships/create' do
    @transport = Transport.find(params[:transport_id]) || not_found
    @gathering = @transport.gathering      
    confirmed_membership_required!      
    Transportship.create(account: current_account, transport_id: params[:transport_id], gathering: @gathering)
    200
  end    
    
  get '/transportships/:id/destroy' do
    @transportship = Transportship.find(params[:id]) || not_found
    @gathering = @transportship.transport.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    halt unless @transportship.account.id == current_account.id or @membership.admin?
    @transportship.destroy
    200
  end 
    
end