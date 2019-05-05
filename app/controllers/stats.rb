Autopia::App.controller do

  get '/stats/comments' do
    admins_only!
    @comments = Comment.order('created_at desc').paginate(:page => params[:page], :per_page => 50)
    erb :'stats/comments'
  end
  
  get '/stats/accounts' do
    admins_only!
    @accounts = Account.order('created_at desc').paginate(:page => params[:page], :per_page => 50)
    erb :'stats/accounts'
  end    
    
end