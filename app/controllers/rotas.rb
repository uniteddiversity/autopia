Huddl::App.controller do
  
  get '/h/:slug/rotas/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    @rota = @group.rotas.build
    erb :'rotas/build'
  end
  
  post '/h/:slug/rotas/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    @rota = @group.rotas.build(params[:rota])
    @rota.account = current_account
    if @rota.save
      redirect "/h/#{@group.slug}/rotas/#{@rota.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the rota from being saved."
      erb :'rotas/build'    
    end
  end

  get '/h/:slug/rotas' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    erb :'rotas/rotas'     
  end     
  
  get '/h/:slug/rotas/:id' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    @rota = @group.rotas.find(params[:id])
    membership_required!
    if request.xhr?
      partial :'rotas/rota', :locals => {:rota => @rota}
    else
      erb :'rotas/rota'
    end
  end
  
  get '/h/:slug/rotas/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    @rota = @group.rotas.find(params[:id])
    erb :'rotas/build'
  end
  
  post '/h/:slug/rotas/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    @rota = @group.rotas.find(params[:id])
    if @rota.update_attributes(params[:rota])
      redirect "/h/#{@group.slug}/rotas/#{@rota.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the rota from being saved." 
      erb :'rotas/build'
    end
  end  
        
  get '/h/:slug/rotas/:id/destroy' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    @rota = @group.rotas.find(params[:id])
    group_admins_only!
    @rota.destroy
    redirect "/h/#{@group.slug}/rotas"      
  end   
  
  post '/roles/order' do
    @rota = Rota.find(params[:rota_id]) || not_found
    @group = @rota.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    params[:role_ids].each_with_index { |role_id,i|
      @rota.roles.find(role_id).update_attribute(:o, i)
    }
    200
  end  
    
  post '/roles/create' do
    @rota = Rota.find(params[:rota_id]) || not_found
    @group = @rota.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    Role.create(name: params[:name], rota: @rota)
    200
  end   
    
  get '/roles/:id/destroy' do
    @role = Role.find(params[:id]) || not_found
    @group = @role.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @role.destroy
    200 
  end     
  
  post '/rslots/order' do
    @rota = Rota.find(params[:rota_id]) || not_found
    @group = @rota.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    params[:rslot_ids].each_with_index { |rslot_id,i|
      @rota.rslots.find(rslot_id).update_attribute(:o, i)
    }
    200
  end    
    
  post '/rslots/create' do
    @rota = Rota.find(params[:rota_id]) || not_found
    @group = @rota.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    Rslot.create(name: params[:name], rota: @rota)
    200
  end      
    
  get '/rslots/:id/destroy' do
    @rslot = Rslot.find(params[:id]) || not_found
    @group = @rslot.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @rslot.destroy
    200    
  end      
    
  get '/rota/rslot/role/:rota_id/:rslot_id/:role_id' do
    @rota = Rota.find(params[:rota_id]) || not_found 
    @rslot = Rslot.find(params[:rslot_id]) || not_found 
    @role = Role.find(params[:role_id]) || not_found 
    @group = @rota.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    partial :'rotas/rota_rslot_role', :locals => {:rota => @rota, :rslot => @rslot, :role => @role}
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