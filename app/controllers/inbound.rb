Huddl::App.controller do

  post '/h/:slug/inbound' do
		EmailReceiver.receive(request)
  end
    
end