Huddl::App.controller do

  post '/h/:slug/inbound/:post_id' do
		mail = EmailReceiver.receive(request)
		raise mail.inspect
  end
    
end