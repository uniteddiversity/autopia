Autopo::App.controller do

  get '/habits' do
    @habit = Habit.new
    @habits = current_account.habits
    @dates = ((Date.today-4)..Date.today).to_a.reverse
    @habit_share = true
    if request.xhr?
      partial :'habits/habits'
    else
      erb :'habits/habits'
    end
  end
  
  get '/a/:slug/habits' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @dates = ((Date.today-4)..Date.today).to_a.reverse    
    erb :'habits/group'
  end
  
  post '/habits/new' do
    @habit = current_account.habits.build(params[:habit])
    if @habit.save
      redirect '/habits'
    else
      flash[:error] = 'There was an error saving the habit.'
      erb :'habits/habits'
    end
  end  
    
  post '/habits/:id/public' do
    @habit = current_account.habits.find(params[:id]) || not_found
    if @habit.public?
      @habit.update_attribute(:public, nil)
    else
      @habit.update_attribute(:public, true)
    end
    200
  end   
  
  get '/habits/:id/destroy' do
    @habit = current_account.habits.find(params[:id]) || not_found
    @habit.destroy
    200    
  end  
  
  post '/habits/:id/completed' do
    @habit = current_account.habits.find(params[:id]) || not_found
    if habit_completion = @habit.habit_completions.find_by(date: params[:date])
      habit_completion.destroy
    else
      @habit.habit_completions.create(date: params[:date])
    end
    request.xhr? ? 200 : redirect(back)
  end    
    
  post '/habits/order' do
    params[:habit_ids].each_with_index { |habit_id,i|
      current_account.habits.find(habit_id).update_attribute(:o, i)
    }
    200
  end  
  
end