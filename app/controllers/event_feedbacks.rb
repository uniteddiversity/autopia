Autopia::App.controller do
  
  before do
    sign_in_required!
  end
  
  get '/events/:id/feedback' do
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    @event_feedbacks = @event.event_feedbacks
    @event_feedbacks = @event_feedbacks.paginate(page: params[:page], per_page: 10)    
    erb :'event_feedbacks/index'
  end        
    
  get '/event_feedbacks/:id' do
    @event_feedback = EventFeedback.find(params[:id]) || not_found
    @event = @event_feedback.event    
    event_admins_only!  
    erb :'event_feedbacks/feedback'
  end  
  
  get '/events/:id/give_feedback' do
    @event = Event.find(params[:id]) || not_found
    @account = (admin? and params[:email]) ? Account.find_by(email: /^#{::Regexp.escape(params[:email])}$/i) : current_account
    unless (@account and @event.attendees.include?(@account))
      flash[:error] = "You didn't attend that event!"
      redirect "/events"
    end    
    if @event.event_feedbacks.find_by(account: @account)
      flash[:error] = "You've already left feedback on that event"
      redirect "/events"      
    end
    @title = "Feedback on #{@event.name}#{ " for #{@account.name}" if params[:email]}"
    @event_feedback = @event.event_feedbacks.build(account: @account)
    erb :'event_feedbacks/build'
  end
    
  post '/events/:id/give_feedback' do
    @event = Event.find(params[:id]) || not_found
    @title = "Feedback on #{@event.name}"
    @event_feedback = @event.event_feedbacks.new(params[:event_feedback])
    @event_feedback.answers = (params[:answers].map { |i,x| [@event.feedback_questions_a[i.to_i],x] } if params[:answers])
    @event_feedback.save!
    flash[:notice] = 'Thanks for your feedback!'
    redirect '/events'
  end  
  
  get '/event_feedbacks/:id/public/:i' do    
    @event_feedback = EventFeedback.find(params[:id])
    @event = @event_feedback.event
    event_admins_only!
    partial :'event_feedbacks/public'
  end
 
  post '/event_feedbacks/:id/public/:i' do   
    @event_feedback = EventFeedback.find(params[:id])
    @event = @event_feedback.event
    event_admins_only!
    
    public_answers = @event_feedback.event.feedback_questions_a.map { |q| [q,''] }
        
    # keep existing answers
    if @event_feedback.public_answers
      public_answers.each_with_index { |qa,i|
        q = qa[0]
        if existing_qa = @event_feedback.public_answers.detect { |k,v| k == q }
          public_answers[i][1] = existing_qa[1]
        end
      }
    end
    
    # set new answer
    public_answers[params[:i].to_i][1] = params[:public]
    
    @event_feedback.public_answers = public_answers.all? { |k,v| v.blank? } ? nil : public_answers
    @event_feedback.save
    200
  end  
  
end