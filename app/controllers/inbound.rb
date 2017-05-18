Huddl::App.controller do

  post '/h/:slug/inbound/:post_id' do
		EmailReceiver.receive(request)
  end
    
end