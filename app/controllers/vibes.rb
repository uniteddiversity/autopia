Autopia::App.controller do
  
  get '/vibes/:id' do
    sign_in_required!
    @account = Account.find(params[:id]) || not_found
    partial :vibe, :locals => {:account => @account, :btn_class => params[:btn_class]}
  end
  
  post '/vibe/:id' do
    sign_in_required!
    @account = Account.find(params[:id]) || not_found
    current_account.vibes_as_viber.create vibee: @account
    200
  end
  
  post '/unvibe/:id' do
    sign_in_required!
    @account = Account.find(params[:id]) || not_found
    current_account.vibes_as_viber.find_by(vibee: @account).try(:destroy)
    200
  end  
  
end