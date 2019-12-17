Autopia::App.controller do
  
  before do
    @organisation = Organisation.find(params[:id]) || not_found    
    organisation_admins_only!
  end
     
  get '/organisations/:id/pmails' do
    @pmails = @organisation.pmails.order('created_at desc').page(params[:page])
    erb :'pmails/pmails'
  end  
      
  get '/organisations/:id/pmails/new' do
    @pmail = Pmail.new
    @pmail.from = "#{current_account.name} <#{current_account.email}>"
    @pmail.body = %Q{Hi %recipient.firstname%,}
    erb :'pmails/build'
  end
  
  post '/organisations/:id/pmails/new' do
    @pmail = Pmail.new(mass_assigning(params[:pmail], Pmail))
    @pmail.account = current_account
    @pmail.organisation = @organisation
    if @pmail.save
      flash[:notice] = %Q{The mail was saved.}
      redirect "/organisations/#{@organisation.id}/pmails/#{@pmail.id}/edit"
    else
      erb :'pmails/build'
    end
  end  

  get '/organisations/:id/pmails/:pmail_id/edit' do
    @pmail = Pmail.find(params[:pmail_id]) || not_found   
    erb :'pmails/build'
  end
  
  post '/organisations/:id/pmails/:pmail_id/edit' do
    @pmail = Pmail.find(params[:pmail_id]) || not_found   
    if @pmail.update_attributes(mass_assigning(params[:pmail], Pmail))
      flash[:notice] = 'The mail was saved.'
      redirect "/organisations/#{@organisation.id}/pmails/#{@pmail.id}/edit"
    else
      erb :'mailer/build'
    end
  end   
  
  get '/organisations/:id/pmails/:pmail_id/destroy' do
    Pmail.find(params[:pmail_id]).destroy
    redirect "/organisations/#{@organisation.id}/pmails"
  end
    
  get '/organisations/:id/pmails/:pmail_id/send_test' do
    @pmail = Pmail.find(params[:pmail_id]) || not_found   
    @pmail.send_test(current_account)
    flash[:notice] = %Q{Test sent}
    redirect "/organisations/#{@organisation.id}/pmails/#{@pmail.id}/edit"
  end   
  
  get '/organisations/:id/pmails/:pmail_id/send' do
    @pmail = Pmail.find(params[:pmail_id]) || not_found   
    @pmail.send_pmail
    flash[:notice] = %Q{Sent!}
    redirect "/organisations/#{@organisation.id}/pmails"
  end  
         
end