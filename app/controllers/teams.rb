Huddl::App.controller do
  
  get '/h/:slug/teams/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @team = Team.new
    erb :'teams/build', :layout => 'layouts/teams' 
  end
  
  post '/h/:slug/teams/new' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @team = @group.teams.build(params[:team])
    @team.account = current_account
    if @team.save
      redirect "/h/#{@group.slug}/teams/#{@team.id}"
    else
      erb :'teams/build', :layout => 'layouts/teams' 
    end
  end
  
  get '/h/:slug/teams' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    if general = @group.teams.find_by(name: 'General')
      redirect "/h/#{@group.slug}/teams/#{general.id}"
    end
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    erb :'teams/teams', :layout => 'layouts/teams' 
  end
  
  get '/h/:slug/teams/:id' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @team = @group.teams.find(params[:id])
    @comment = @team.comments.build
    if request.xhr?
      partial :'teams/team'
    else
      erb :'teams/team', :layout => 'layouts/teams' 
    end
  end
  
  get '/h/:slug/teams/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @team = @group.teams.find(params[:id])
    erb :'teams/build', :layout => 'layouts/teams' 
  end  
  
  post '/h/:slug/teams/:id/edit' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @team = @group.teams.find(params[:id])
    if @team.update_attributes(params[:team])
      redirect "/h/#{@group.slug}/teams/#{@team.id}"
    else
      erb :'teams/build', :layout => 'layouts/teams' 
    end
  end    
  
  get '/h/:slug/teams/:id/destroy' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @team = @group.teams.find(params[:id])
    @team.destroy
    redirect "/h/#{@group.slug}/teams"
  end    
    
  post '/h/:slug/teams/:id/comment' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @team = @group.teams.find(params[:id])    
    @comment = @team.comments.build(params[:comment])
    @comment.account = current_account
    if !@comment.post
      @post = @team.posts.create!(account: current_account)
      @comment.post = @post
    end
    if @comment.save
      request.xhr? ? 200 : redirect("/h/#{@group.slug}/teams/#{@team.id}#post-#{@comment.post_id}")
    else
      @post.destroy if @post
      flash[:error] = 'There was an error saving the comment'
      erb :'teams/team', :layout => 'layouts/teams' 
    end
  end
  
  post '/h/:slug/inbound/:id' do    
		mail, html, plain_text = EmailReceiver.receive(request)				    			
		account = Account.find_by(email: mail.from.first)
		@group = Group.find_by(slug: params[:slug]) || not_found  
		@membership = @group.memberships.find_by(account: account)
		membership_required!(@group, account)
		@post = @group.posts.find(params[:id])
		@post.comments.create! account: account, body: plain_text		
		200
  end    
  
  get '/comments/:id/edit' do
    @comment = Comment.find(params[:id]) || not_found
    @team = @comment.team
    @group = @comment.group
    @membership = @group.memberships.find_by(account: current_account)
    halt unless @comment.account.id == current_account.id or @membership.admin?
    erb :'teams/comment_build', :layout => 'layouts/teams' 
  end
  
  post '/comments/:id/edit' do
    @comment = Comment.find(params[:id]) || not_found
    @team = @comment.team
    @group = @comment.group
    @membership = @group.memberships.find_by(account: current_account)
    halt unless @comment.account.id == current_account.id or @membership.admin?
    if @comment.update_attributes(params[:comment])
      redirect "/h/#{@group.slug}/teams/#{@team.id}#post-#{@comment.post_id}"
    else
      flash[:error] = 'There was an error saving the comment'
      erb :'teams/team'
    end
  end  
  
  get '/comments/:id/destroy' do
    @comment = Comment.find(params[:id]) || not_found
    @team = @comment.team
    @group = @comment.group
    @membership = @group.memberships.find_by(account: current_account)
    halt unless @comment.account.id == current_account.id or @membership.admin?
    @comment.destroy
    redirect "/h/#{@group.slug}/teams/#{@team.id}"
  end  
  
  get '/comments/:id/likes' do
    @comment = Comment.find(params[:id]) || not_found
    @team = @comment.team
    @group = @comment.group
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required!
    partial :'teams/comment_likes', :locals => {:comment => @comment}
  end  
  
  get '/comments/:id/like' do
    @comment = Comment.find(params[:id]) || not_found
    @team = @comment.team
    @group = @comment.group
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required!
    @comment.comment_likes.create account: current_account
    200
  end
  
  get '/comments/:id/unlike' do
    @comment = Comment.find(params[:id]) || not_found
    @team = @comment.team
    @group = @comment.group
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required!
    @comment.comment_likes.find_by(account: current_account).try(:destroy)
    200
  end  
           
  get '/teamships/create' do
    @team = Team.find(params[:team_id]) || not_found
    @group = @team.group      
    membership_required!      
    Teamship.create(account: current_account, team_id: params[:team_id])
    redirect back
  end    
    
  get '/teamships/:id/destroy' do
    @teamship = Teamship.find(params[:id]) || not_found
    @group = @teamship.team.group
    @membership = @group.memberships.find_by(account: current_account)
    halt unless @teamship.account.id == current_account.id or @membership.admin?
    @teamship.destroy
    redirect back
  end  
  
  get '/posts/:id' do
    @post = Post.find(params[:id]) || not_found
    @team = @post.team
    @group = @post.group
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required!
    partial :'teams/post', :locals => {:post => @post}
  end
  
  get '/posts/:id/unsubscribe' do
    @post = Post.find(params[:id]) || not_found
    @team = @post.team
    @group = @post.group
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required!    
    @post.subscriptions.find_by(account: current_account).destroy
    flash[:notice] = "You unsubscribed from the post"
    redirect "/h/#{@group.slug}/teams/#{@team.id}#post-#{@post.id}"        
  end    
  
  get '/posts/:id/replies' do
    @post = Post.find(params[:id]) || not_found
    @team = @post.team
    @group = @post.group
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required!
    partial :'teams/replies', :locals => {:post => @post}
  end  
    
  get '/comments/:id/options' do
    @comment = Comment.find(params[:id]) || not_found
    @team = @comment.team
    @group = @comment.group
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required!
    partial :'teams/options', :locals => {:comment => @comment}
  end
  
  post '/options/create' do
    @comment = Comment.find(params[:comment_id]) || not_found
    @group = @comment.group      
    membership_required!      
    @comment.options.create!(account: current_account, text: params[:text])
    200   
  end  
  
  post '/options/:id/vote' do
    @option = Option.find(params[:id]) || not_found
    @group = @option.comment.group      
    membership_required!      
    if params[:vote]
      @option.votes.create!(account: current_account)
    else
      @option.votes.find_by(account: current_account).try(:destroy)
    end
    200
  end  
  
  get '/options/:id/destroy' do
    @option = Option.find(params[:id]) || not_found
    @group = @option.comment.group      
    membership_required!      
    @option.destroy
    redirect back
  end    
  
  get '/subscriptions/create' do
    @post = Post.find(params[:post_id]) || not_found
    @group = @post.group      
    membership_required!      
    @post.subscriptions.create!(account: current_account)
    200   
  end      
  
  get '/subscriptions/:id/destroy' do
    @subscription = Subscription.find(params[:id]) || not_found
    @group = @subscription.group      
    membership_required!      
    @subscription.destroy
    200        
  end
    
end