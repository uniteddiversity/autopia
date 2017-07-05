Huddl::App.controller do
  
  get '/h/:slug/wishlists/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    group_admins_only!
    @wishlist = @group.wishlists.build        
    erb :'wishlists/build'
  end
  
  post '/h/:slug/wishlists/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @wishlist = @group.wishlists.build(params[:wishlist])      
    @wishlist.account = current_account    
    if @wishlist.save
      redirect "/h/#{@group.slug}/wishlists/#{@wishlist.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the wishlist from being saved."
      erb :'wishlists/build'    
    end
  end

  get '/h/:slug/wishlists' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    erb :'wishlists/wishlists'     
  end     
  
  get '/h/:slug/wishlists/:id' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @wishlist = @group.wishlists.find(params[:id]) || not_found
    @wishlist_item = @wishlist.wishlist_items.new
    if request.xhr?
      partial :'wishlists/wishlist', :locals => {:wishlist => @wishlist}
    else
      erb :'wishlists/wishlist'
    end
  end
  
  get '/h/:slug/wishlists/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @wishlist = @group.wishlists.find(params[:id]) || not_found
    erb :'wishlists/build'
  end
  
  post '/h/:slug/wishlists/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @wishlist = @group.wishlists.find(params[:id]) || not_found
    if @wishlist.update_attributes(params[:wishlist])
      redirect "/h/#{@group.slug}/wishlists/#{@wishlist.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the wishlist from being saved." 
      erb :'wishlists/build'
    end
  end  
        
  get '/h/:slug/wishlists/:id/destroy' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!    
    @wishlist = @group.wishlists.find(params[:id]) || not_found
    @wishlist.destroy
    redirect "/h/#{@group.slug}/wishlists"      
  end   
  
  post '/wishlists/:id/wishlist_items/new' do
    @wishlist = Wishlist.find(params[:id])
    @group = @wishlist.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @wishlist_item = @wishlist.wishlist_items.build(params[:wishlist_item])      
    @wishlist_item.account = current_account    
    if @wishlist_item.save
      redirect "/h/#{@group.slug}/wishlists/#{@wishlist.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the item from being saved."
      erb :'wishlists/build'    
    end        
  end
  
 get '/wishlists/:wishlist_id/wishlist_items/:id/edit' do
    @wishlist = Wishlist.find(params[:wishlist_id])
    @group = @wishlist.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @wishlist_item = @wishlist.wishlist_items.find(params[:id]) || not_found
    erb :'wishlists/build_wishlist_item'
  end
        
 post '/wishlists/:wishlist_id/wishlist_items/:id/edit' do
    @wishlist = Wishlist.find(params[:wishlist_id])
    @group = @wishlist.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @wishlist_item = @wishlist.wishlist_items.find(params[:id]) || not_found
    if @wishlist_item.update_attributes(params[:wishlist_item])
      redirect "/h/#{@group.slug}/wishlists/#{@wishlist.id}"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the wishlist_item from being saved." 
      erb :'wishlists/build_wishlist_item'
    end
  end  
        
 get '/wishlists/:wishlist_id/wishlist_items/:id/destroy' do
    @wishlist = Wishlist.find(params[:wishlist_id])
    @group = @wishlist.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only! 
    @wishlist_item = @wishlist.wishlist_items.find(params[:id]) || not_found
    @wishlist_item.destroy
    redirect "/h/#{@group.slug}/wishlists/#{@wishlist.id}"
  end   
  
 post '/wishlists/:wishlist_id/wishlist_items/:id/provided' do
    @wishlist = Wishlist.find(params[:wishlist_id])
    @group = @wishlist.group
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @wishlist_item = @wishlist.wishlist_items.find(params[:id]) || not_found
    @wishlist_item.update_attribute(:provided_by, params[:provided_by_id])
    200
  end   
        
end