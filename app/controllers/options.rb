Autopia::App.controller do
    
  post '/a/:slug/options/new' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    discuss 'Options'
    gathering_admins_only!    
    @option = @gathering.options.build(params[:option])
    @option.account = current_account
    if @option.save
      redirect "/a/#{@gathering.slug}/options"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the option from being saved."
      erb :'options/build'    
    end
  end  
  
  get '/a/:slug/options' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    discuss 'Options'
    confirmed_membership_required!
    if request.xhr?
      partial :'options/options'
    else
      erb :'options/options'
    end
  end
    
  get '/a/:slug/options/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    discuss 'Options'
    gathering_admins_only!    
    @option = @gathering.options.find(params[:id])
    erb :'options/build'
  end
  
  post '/a/:slug/options/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    discuss 'Options'
    gathering_admins_only!    
    @option = @gathering.options.find(params[:id])
    if @option.update_attributes(mass_assigning(params[:option], Option))
      redirect "/a/#{@gathering.slug}/options"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the option from being saved." 
      erb :'options/build'
    end
  end  
  
  get '/a/:slug/options/:id/destroy' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!    
    @option = @gathering.options.find(params[:id])
    @option.destroy
    redirect "/a/#{@gathering.slug}/options"      
  end 
    
  get '/optionships/create' do
    @option = Option.find(params[:option_id]) || not_found
    @gathering = @option.gathering      
    confirmed_membership_required!      
    Optionship.create(account: current_account, option_id: params[:option_id], gathering: @gathering)
    200
  end    
    
  get '/optionships/:id/destroy' do
    @optionship = Optionship.find(params[:id]) || not_found
    @gathering = @optionship.option.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    halt unless @optionship.account.id == current_account.id or @membership.admin?
    @optionship.destroy
    200
  end        
  
end