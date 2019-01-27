Autopo::App.controller do
  
  before do
    sign_in_required!
  end
    
  get '/messages' do
    message = current_account.messages.order('created_at desc').first
    if message
      account = (current_account == message.messenger ? message.messengee : message.messenger)
      redirect "/messages/#{account.id}"
    else
      redirect '/search'
    end
  end
  
  get '/messages/:id' do    
    @account = Account.find(params[:id])
    if @account.id == current_account.id
      flash[:notice] = "You can't message yourself"
      redirect '/messages'
    end
    MessageReceipt.find_by(messenger: @account, messengee: current_account).try(:destroy)
    MessageReceipt.create!(messenger: @account, messengee: current_account)
    if request.xhr?
      partial :'messages/thread'
    else    
      erb :'messages/messages'
    end
  end  
  
  post '/messages/:id' do    
    Message.create!(body: params[:body], messenger: current_account, messengee_id: params[:id])
    redirect back
  end
 
end