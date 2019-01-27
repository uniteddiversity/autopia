Autopo::App.controller do
  
  before do
    sign_in_required!
  end
    
  get '/messages' do    
    if request.xhr?
      partial :'messages/dropdown'
    else   
      message = current_account.messages.order('created_at desc').first
      if message
        account = (current_account == message.messenger ? message.messengee : message.messenger)
        redirect "/messages/#{account.id}"
      else
        redirect '/search'
      end
    end
  end
  
  get '/messages/:id' do    
    @account = Account.find(params[:id])
    if @account.id == current_account.id
      flash[:notice] = "You can't message yourself"
      redirect '/messages'
    end
    message_receipt = MessageReceipt.find_by(messenger: @account, messengee: current_account) || MessageReceipt.create!(messenger: @account, messengee: current_account)
    message_receipt.set(created_at: Time.now)    
    if request.xhr?
      partial :'messages/thread'
    else    
      erb :'messages/messages'
    end
  end  
  
  get '/messages/:id/send' do  
    @account = Account.find(params[:id])
    partial :'messages/send'
  end
  
  post '/messages/:id/send' do    
    Message.create!(body: params[:body], messenger: current_account, messengee_id: params[:id])
    redirect back
  end
 
end