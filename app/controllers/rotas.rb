Huddl::App.controller do

  get '/h/:slug/rotas' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    erb :rotas     
  end     
    
  post '/rotas/create' do
    @group = Group.find(params[:group_id]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    Rota.create(name: params[:name], group: @group, account: current_account)
    redirect back
  end
    
  get '/rotas/:id/destroy' do
    @rota = Rota.find(params[:id]) || not_found
    @group = @rota.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @rota.destroy
    redirect back      
  end   
    
  post '/roles/create' do
    @rota = Rota.find(params[:rota_id]) || not_found
    @group = @rota.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    Role.create(name: params[:name], rota: @rota)
    redirect back
  end   
    
  get '/roles/:id/destroy' do
    @role = Role.find(params[:id]) || not_found
    @group = @role.rota.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @role.destroy
    redirect back      
  end     
    
  post '/rslots/create' do
    @rota = Rota.find(params[:rota_id]) || not_found
    @group = @rota.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    Rslot.create(name: params[:name], rota: @rota)
    redirect back
  end      
    
  get '/rslots/:id/destroy' do
    @rslot = Rslot.find(params[:id]) || not_found
    @group = @rslot.rota.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @rslot.destroy
    redirect back      
  end      
    
  get '/rota/rslot/role/:rota_id/:rslot_id/:role_id' do
    @rota = Rota.find(params[:rota_id]) || not_found 
    @rslot = Rslot.find(params[:rslot_id]) || not_found 
    @role = Role.find(params[:role_id]) || not_found 
    @group = @rota.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    partial :rota_rslot_role, :locals => {:rota => @rota, :rslot => @rslot, :role => @role}
  end
         
  get '/shifts/create' do
    @rota = Rota.find(params[:rota_id]) || not_found 
    @group = @rota.group
    membership_required!
    Shift.create(account: (params[:na] ? nil : current_account), rota_id: params[:rota_id], rslot_id: params[:rslot_id], role_id: params[:role_id])
    200
  end      
    
  get '/shifts/:id/destroy' do
    @shift = Shift.find(params[:id]) || not_found
    @group = @shift.rota.group
    @membership = @group.memberships.find_by(account: current_account)
    halt unless (@shift.account and @shift.account.id == current_account.id) or @membership.admin?
    @shift.destroy
    200
  end    
    
end