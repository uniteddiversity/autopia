Autopo::App.controller do
  
  get '/h/:slug/timetracker' do    
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    confirmed_membership_required!
    @from = params[:from] ? Date.parse(params[:from]) : Date.new(Date.today.year,Date.today.month,1)
    @to = params[:to] ? Date.parse(params[:to]) : Date.today
    @work_periods = @group.work_periods.where(:start_time.gte => @from, :start_time.lt => @to+1)
    @accounts = Account.where(:id.in => @work_periods.pluck(:account_id)).order('name asc')
    erb :'work_periods/timetracker'
  end
  
  post '/h/:slug/work_periods/start' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    confirmed_membership_required!
    @group.work_periods.create! start_time: params[:work_period][:start_time], account: current_account
    redirect back
  end
  
  post '/h/:slug/work_periods/end' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    confirmed_membership_required!
    w = @membership.current_work_period
    w.end_time = params[:work_period][:end_time] || Time.now
    w.description = params[:work_period][:description]
    w.save!
    redirect back
  end
  
  get '/h/:slug/work_periods/:id/destroy' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)        
    confirmed_membership_required!
    @membership.work_periods.find(params[:id]).destroy
    redirect back
  end
  
end