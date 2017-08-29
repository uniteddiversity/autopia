Huddl::App.controller do
	
  get '/mapplications/:id' do
    @mapplication = Mapplication.find(params[:id]) || not_found
    @group = @mapplication.group
    @membership = @group.memberships.find_by(account: current_account)      
    membership_required!
    partial :'mapplications/mapplication', :object => @mapplication
  end
    
  get '/mapplication_row/:id' do
    @mapplication = Mapplication.find(params[:id]) || not_found
    @group = @mapplication.group
    @membership = @group.memberships.find_by(account: current_account)      
    membership_required!
    if @mapplication.status == 'accepted'
      200
    else
      partial :'mapplications/mapplication_row', :locals => {:mapplication => @mapplication}
    end
  end    	
	
  get '/h/:slug/apply' do      
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    @title = "#{@group.name} · #{ENV['SITE_TITLE']}"
    @og_desc = "#{@group.name} is being co-created on #{ENV['SITE_TITLE']}"
    @og_image = @group.image ? @group.image.url : ENV['SITE_IMAGE']
    @account = Account.new
    erb :'mapplications/apply'
  end    
    
  post '/h/:slug/apply' do
    @group = Group.find_by(slug: params[:slug]) || not_found

    if current_account
      @account = current_account
    else           
      redirect back unless params[:account] and params[:account][:email]
      if !(@account = Account.find_by(email: /^#{::Regexp.escape(params[:account][:email])}$/i))
        @account = Account.new(params[:account])
        @account.password = Account.generate_password(8) # not used
        if !@account.save
          flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
          halt 400, (erb :'mapplications/apply')
        end
      end
    end    
    
    if @group.memberships.find_by(account: @account)
      flash[:notice] = "You're already part of that group"
      redirect back
    elsif @group.mapplications.find_by(account: @account)
      flash[:notice] = "You've already applied to that group"
      redirect back
    else
      @mapplication = @group.mapplications.create! :account => @account, :status => 'pending', :answers => (params[:answers].map { |i,x| [@group.application_questions_a[i.to_i],x] } if params[:answers])
      redirect "/h/#{@group.slug}/apply?applied=true"
    end    
  end
           
  get '/h/:slug/applications' do     
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!    
    @mapplications = @group.mapplications.pending
    @mapplications = @mapplications.where(:account_id.in => Account.where(name: /#{::Regexp.escape(params[:q])}/i).pluck(:id)) if params[:q]
    erb :'mapplications/pending'
  end   
    
  get '/h/:slug/threshold' do     
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    partial :'mapplications/threshold'
  end     
    
  post '/h/:slug/threshold' do     
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!      
    @membership.desired_threshold = params[:desired_threshold]
    @membership.save!
    200
  end         
    
  get '/h/:slug/applications/on_ice' do     
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @mapplications = @group.mapplications.on_ice
    erb :'mapplications/on_ice'
  end     
  
  get '/verdicts/create' do
    @mapplication = Mapplication.find(params[:mapplication_id]) || not_found
    @group = @mapplication.group      
    membership_required!
    Verdict.create(account: current_account, mapplication_id: params[:mapplication_id], type: params[:type], reason: params[:reason])
    200
  end       
    
  get '/verdicts/:id/destroy' do
    @verdict = Verdict.find(params[:id]) || not_found
    halt unless @verdict.account.id == current_account.id
    @verdict.destroy
    200
  end     
  
  get '/mapplications/:id/process' do
    @mapplication = Mapplication.find(params[:id]) || not_found
    @group = @mapplication.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @mapplication.status = params[:status]
    @mapplication.processed_by = current_account
    @mapplication.save!
    if @mapplication.acceptable? and params[:status] == 'accepted'
      @mapplication.accept    
    end
    redirect back
  end   

  get '/mapplications/:id/destroy' do
    @mapplication = Mapplication.find(params[:id]) || not_found
    @group = @mapplication.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @mapplication.destroy
    redirect back
  end  

end