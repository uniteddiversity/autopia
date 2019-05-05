Autopia::App.controller do

  get '/features/:id' do
    @feature = Feature.find(params[:id]) || not_found
    request.xhr? ? partial(:'features/feature', :object => @feature) : erb(:'features/feature')
  end
  
end