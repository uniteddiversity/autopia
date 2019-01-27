Autopo::App.controller do
  
  before do
    sign_in_required!
  end
    
  get '/messages' do
    message = current_account.messages.order('created_at desc').first
    if message
      account = (current_account == message.messanger ? message.messangee : message.messanger)
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
    MessageReceipt.find_by(messanger: @account, messangee: current_account).try(:destroy)
    MessageReceipt.create!(messanger: @account, messangee: current_account)
    if request.xhr?
      partial :'messages/thread'
    else    
      erb :'messages/messages'
    end
  end  
  
  post '/messages/:id' do    
    Message.create!(body: params[:body], messanger: current_account, messangee_id: params[:id])
    redirect back
  end
 
end