Autopia::App.controller do
  
  get '/a/:slug/rotas/new' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)    
    gathering_admins_only!
    @rota = @gathering.rotas.build        
    erb :'rotas/build'
  end
  
  post '/a/:slug/rotas/new' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    @rota = @gathering.rotas.build(params[:rota])      
    @rota.account = current_account    
    if @rota.save
      redirect "/a/#{@gathering.slug}/rotas/#{@rota.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the rota from being saved."
      erb :'rotas/build'    
    end
  end

  get '/a/:slug/rotas' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    discuss 'Rotas'
    erb :'rotas/rotas'     
  end     
  
  get '/a/:slug/rotas/:id' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @rota = @gathering.rotas.find(params[:id]) || not_found
    if request.xhr?
      partial :'rotas/rota', :locals => {:rota => @rota}
    else
      discuss 'Rotas'
      erb :'rotas/rota'
    end
  end
  
  get '/a/:slug/rotas/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    @rota = @gathering.rotas.find(params[:id]) || not_found
    erb :'rotas/build'
  end
  
  post '/a/:slug/rotas/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    @rota = @gathering.rotas.find(params[:id]) || not_found
    if @rota.update_attributes(mass_assigning(params[:rota], Rota))
      redirect "/a/#{@gathering.slug}/rotas/#{@rota.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the rota from being saved." 
      erb :'rotas/build'
    end
  end  
        
  get '/a/:slug/rotas/:id/destroy' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!    
    @rota = @gathering.rotas.find(params[:id]) || not_found
    @rota.destroy
    redirect "/a/#{@gathering.slug}/rotas"      
  end   
  
  post '/roles/order' do
    @rota = Rota.find(params[:rota_id]) || not_found
    @gathering = @rota.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    params[:role_ids].each_with_index { |role_id,i|
      @rota.roles.find(role_id).update_attribute(:o, i)
    }
    200
  end  
    
  post '/roles/create' do
    @rota = Rota.find(params[:rota_id]) || not_found
    @gathering = @rota.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    Role.create(name: params[:name], rota: @rota)
    200
  end   
    
  get '/roles/:id/destroy' do
    @role = Role.find(params[:id]) || not_found
    @gathering = @role.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    @role.destroy
    200 
  end     
  
  post '/rslots/order' do
    @rota = Rota.find(params[:rota_id]) || not_found
    @gathering = @rota.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    params[:rslot_ids].each_with_index { |rslot_id,i|
      @rota.rslots.find(rslot_id).update_attribute(:o, i)
    }
    200
  end    
    
  post '/rslots/create' do
    @rota = Rota.find(params[:rota_id]) || not_found
    @gathering = @rota.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    Rslot.create(name: params[:name], rota: @rota)
    200
  end      
    
  get '/rslots/:id/destroy' do
    @rslot = Rslot.find(params[:id]) || not_found
    @gathering = @rslot.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    @rslot.destroy
    200    
  end      
    
  get '/rota/rslot/role/:rota_id/:rslot_id/:role_id' do
    @rota = Rota.find(params[:rota_id]) || not_found 
    @rslot = Rslot.find(params[:rslot_id]) || not_found 
    @role = Role.find(params[:role_id]) || not_found 
    @gathering = @rota.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    partial :'rotas/rota_rslot_role', :locals => {:rota => @rota, :rslot => @rslot, :role => @role}
  end
         
  get '/shifts/create' do
    @rota = Rota.find(params[:rota_id]) || not_found 
    @gathering = @rota.gathering
    confirmed_membership_required!
    Shift.create(account: (params[:na] ? nil : current_account), rota_id: params[:rota_id], rslot_id: params[:rslot_id], role_id: params[:role_id])
    200
  end      
    
  get '/shifts/:id/destroy' do
    @shift = Shift.find(params[:id]) || not_found
    @gathering = @shift.rota.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    halt unless (@shift.account and @shift.account.id == current_account.id) or @membership.admin?
    @shift.destroy
    200
  end    
    
end