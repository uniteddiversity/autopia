Autopo::App.controller do
  
  get '/a/:slug/inventory' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @inventory_item = @group.inventory_items.build(params[:inventory_item])          
    if request.xhr?
      partial :'inventory/inventory'
    else
      erb :'inventory/inventory'  
    end    
  end  
  
  post '/a/:slug/inventory_items/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @inventory_item = @group.inventory_items.build(params[:inventory_item])      
    @inventory_item.account = current_account    
    if @inventory_item.save
      redirect "/a/#{@group.slug}/inventory"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the item from being saved."
      erb :'inventory/build'    
    end        
  end
  
  get '/a/:slug/inventory_items/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @inventory_item = @group.inventory_items.find(params[:id]) || not_found
    erb :'inventory/build'
  end
        
  post '/a/:slug/inventory_items/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @inventory_item = @group.inventory_items.find(params[:id]) || not_found
    if @inventory_item.update_attributes(params[:inventory_item])
      redirect "/a/#{@group.slug}/inventory"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the inventory item from being saved." 
      erb :'inventory/build'
    end
  end  
        
  get '/a/:slug/inventory_items/:id/destroy' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required! 
    @inventory_item = @group.inventory_items.find(params[:id]) || not_found
    @inventory_item.destroy
    redirect "/a/#{@group.slug}/inventory"
  end   
  
  post '/a/:slug/inventory_items/:id/provided' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @inventory_item = @group.inventory_items.find(params[:id]) || not_found
    @inventory_item.update_attribute(:responsible, params[:responsible_id])
    200
  end   
        
end