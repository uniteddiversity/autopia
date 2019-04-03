Autopia::App.controller do
  
  get '/follows/:id' do
    sign_in_required!
    @account = Account.find(params[:id]) || not_found
    partial :follow, :locals => {:account => @account, :btn_class => params[:btn_class]}
  end
  
  post '/follow/:id' do
    sign_in_required!
    @account = Account.find(params[:id]) || not_found
    current_account.follows_as_follower.create followee: @account
    200
  end
  
  post '/unfollow/:id' do
    sign_in_required!
    @account = Account.find(params[:id]) || not_found
    current_account.follows_as_follower.find_by(followee: @account).try(:destroy)
    200
  end  
  
  get '/unfollow/:id' do
    sign_in_required!
    @account = Account.find(params[:id]) || not_found
    current_account.follows_as_follower.find_by(followee: @account).try(:destroy)
    redirect "/u/#{@account.username}"
  end    
  
end