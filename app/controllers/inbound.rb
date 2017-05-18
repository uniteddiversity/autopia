Huddl::App.controller do

  post '/h/:slug/inbound' do
    @group = Group.find_by(slug: params[:slug]) || not_found      
    raise 'inbound'
  end
    
end