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
        erb :'messages/messages'
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
    MessageReceipt.find_or_create_by(messenger: @account, messengee: current_account).set(received_at: Time.now)
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