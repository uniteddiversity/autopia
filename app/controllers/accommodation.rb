Autopia::App.controller do
    
  post '/a/:slug/accoms/new' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!    
    @accom = @gathering.accoms.build(params[:accom])
    @accom.account = current_account
    if @accom.save
      redirect "/a/#{@gathering.slug}/accoms"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the accommodation from being saved."
      erb :'accoms/build'    
    end
  end  
  
  get '/a/:slug/accoms' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    discuss 'Accommodation'
    confirmed_membership_required!
    if request.xhr?
      partial :'accoms/accoms'
    else
      erb :'accoms/accoms'
    end
  end
    
  get '/a/:slug/accoms/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!    
    @accom = @gathering.accoms.find(params[:id])
    erb :'accoms/build'
  end
  
  post '/a/:slug/accoms/:id/edit' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!    
    @accom = @gathering.accoms.find(params[:id])
    if @accom.update_attributes(mass_assigning(params[:accom], Accom))
      redirect "/a/#{@gathering.slug}/accoms"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the accommodation from being saved." 
      erb :'accoms/build'
    end
  end  
  
  get '/a/:slug/accoms/:id/destroy' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!    
    @accom = @gathering.accoms.find(params[:id])
    @accom.destroy
    redirect "/a/#{@gathering.slug}/accoms"      
  end 
    
  get '/accomships/create' do
    @accom = Accom.find(params[:accom_id]) || not_found
    @gathering = @accom.gathering      
    confirmed_membership_required!      
    Accomship.create(account: current_account, accom_id: params[:accom_id], gathering: @gathering)
    200
  end    
    
  get '/accomships/:id/destroy' do
    @accomship = Accomship.find(params[:id]) || not_found
    @gathering = @accomship.accom.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    halt unless @accomship.account.id == current_account.id or @membership.admin?
    @accomship.destroy
    200
  end        
  
end