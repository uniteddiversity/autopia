Autopia::App.controller do
  
  before do
    admins_only!
  end
     
  get '/mailer' do
    @pmails = Pmail.order('created_at desc').page(params[:page])
    erb :'mailer/index'
  end
  
  get '/mailer/help' do
    erb :'mailer/help'
  end 
    
  get '/mailer/new' do
    @pmail = Pmail.new
    @pmail.from = "#{current_account.name} <#{current_account.email}>"
    @pmail.body = %Q{<p>Hi %recipient.firstname%,</p>}
    erb :'mailer/build'
  end
  
  post '/mailer/new' do
    @pmail = Pmail.new(params[:pmail])
    @pmail.account = current_account
    if @pmail.save
      flash[:notice] = %Q{The mail was saved.}
      redirect "/mailer/#{@pmail.id}/edit"
    else
      erb :'mailer/build'
    end
  end  

  get '/mailer/:id/edit' do
    @pmail = Pmail.find(params[:id]) || not_found   
    erb :'mailer/build'
  end
  
  post '/mailer/:id/edit' do
    @pmail = Pmail.find(params[:id])
    if @pmail.update_attributes(params[:pmail])
      flash[:notice] = 'The mail was saved.'
      redirect "/mailer/#{@pmail.id}/edit"
    else
      erb :'mailer/build'
    end
  end   
  
  get '/mailer/:id/destroy' do
    Pmail.find(params[:id]).destroy
    redirect '/mailer'
  end
    
  get '/mailer/:id/send_test' do
    @pmail = Pmail.find(params[:id])    
    @pmail.send_test(current_account)
    flash[:notice] = %Q{Test sent}
    redirect "/mailer/#{@pmail.id}/edit"
  end   
  
  get '/mailer/:id/send' do
    @pmail = Pmail.find(params[:id])    
    @pmail.send_pmail
    flash[:notice] = %Q{Sent!}
    redirect '/mailer'
  end   
       
end