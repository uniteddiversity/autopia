Autopia::App.controller do
  get '/events' do
    @events = Event.future
    @places = @places.where(name: /#{::Regexp.escape(params[:q])}/i) if params[:q]
    discuss 'Events'
    erb :'events/events'
  end

  get '/events/new' do
    sign_in_required!
    @event = Event.new(feedback_questions: 'Comments/suggestions')
    erb :'events/build'
  end

  post '/events/new' do
    sign_in_required!
    @event = Event.new(params[:event])
    @event.account = current_account
    if @event.save
      redirect "/events/#{@event.slug}"
    else
      flash[:error] = 'There was an error saving the event'
      erb :'events/build'
    end
  end

  get '/events/:slug' do
    @event = Event.find_by(slug: params[:slug]) || not_found
    erb :'events/event'
  end

  get '/events/:slug/edit' do
    @event = Event.find_by(slug: params[:slug]) || not_found
    unless admin? || creator?(@event)
      flash[:error] = "You can't edit that event"
      redirect "/events/#{@event.slug}"
    end
    erb :'events/build'
  end

  post '/events/:slug/edit' do
    @event = Event.find_by(slug: params[:slug]) || not_found
    unless admin? || creator?(@event)
      flash[:error] = "You can't edit that event"
      redirect "/events/#{@event.slug}"
    end
    if @event.update_attributes(params[:event])
      redirect "/events/#{@event.slug}"
    else
      flash[:error] = 'There was an error saving the event'
      erb :'events/build'
    end
  end
end
