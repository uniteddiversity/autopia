Autopo::App.controller do
  
  get '/vibe/:id' do
    sign_in_required!
    @account = Account.find(params[:id]) || not_found
    current_account.vibes_as_viber.create vibee: @account
    redirect back
  end
  
  get '/unvibe/:id' do
    sign_in_required!
    @account = Account.find(params[:id]) || not_found
    current_account.vibes_as_viber.find_by(vibee: @account).destroy
    redirect back
  end  
  
end