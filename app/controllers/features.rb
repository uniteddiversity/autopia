Autopia::App.controller do

  get '/features/:id' do
    sign_in_required!
    @feature = Feature.find(params[:id]) || not_found
    request.xhr? ? partial(:'features/feature', :object => @feature) : erb(:'features/feature')
  end
  
end