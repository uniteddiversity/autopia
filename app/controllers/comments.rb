Autopo::App.controller do

  post '/inbound/:id' do    
		mail, html, plain_text = EmailReceiver.receive(request)				    			
		account = Account.find_by(email: mail.from.first)
		@post = Post.find(params[:id])
		@post.comments.create! account: account, body: plain_text		
		200
  end    

  get '/commentable' do
    @commentable = params[:commentable_type].constantize.find(params[:commentable_id])      
    partial :'comments/commentable', :locals => {:commentable => @commentable}
  end
  
  post '/comment' do
    @commentable = params[:comment][:commentable_type].constantize.find(params[:comment][:commentable_id])        
    subject = params[:comment].delete(:subject)
    @comment = @commentable.comments.build(params[:comment])
    @comment.account = current_account
    if !@comment.post
      @post = @commentable.posts.create!(account: current_account, subject: subject)
      @comment.post = @post
    end
    if @comment.save
      request.xhr? ? 200 : redirect(back)
        # redirect("/a/#{@group.slug}/#{@comment.commentable_type.underscore.pluralize}/#{@comment.commentable_id}#post-#{@comment.post_id}")
    else
      @post.destroy if @post
      flash[:error] = 'There was an error saving the comment'
      erb :'comments/comment_build'
    end
  end  
    
  get '/comments/:id/edit' do
    @comment = Comment.find(params[:id]) || not_found
    @commentable = @comment.commentable
    halt unless @comment.account.id == current_account.id or @membership.admin?
    @show_buttons = true
    erb :'comments/comment_build'
  end
  
  post '/comments/:id/edit' do
    @comment = Comment.find(params[:id]) || not_found
    @commentable = @comment.commentable
    halt unless @comment.account.id == current_account.id or @membership.admin?
    if @comment.update_attributes(params[:comment])
      redirect back
      # redirect "/a/#{@group.slug}/#{@comment.commentable_type.underscore.pluralize}/#{@comment.commentable_id}#post-#{@comment.post_id}"
    else
      flash[:error] = 'There was an error saving the comment'
      erb :'comments/comment_build'
    end
  end  
  
  get '/comments/:id/destroy' do
    @comment = Comment.find(params[:id]) || not_found
    @commentable = @comment.commentable
    halt unless @comment.account.id == current_account.id or @membership.admin?
    @comment.destroy
    redirect back
    # redirect "/a/#{@group.slug}/#{@comment.commentable_type.underscore.pluralize}/#{@comment.commentable_id}"
  end  
  
  get '/comments/:id/likes' do
    @comment = Comment.find(params[:id]) || not_found
    @commentable = @comment.commentable
    partial :'comments/comment_likes', :locals => {:comment => @comment}
  end  
  
  get '/comments/:id/read_receipts' do
    @comment = Comment.find(params[:id]) || not_found
    @commentable = @comment.commentable
    partial :'comments/read_receipts', :locals => {:comment => @comment}
  end   
  
  get '/comments/:id/like' do
    @comment = Comment.find(params[:id]) || not_found
    @commentable = @comment.commentable
    @comment.comment_likes.create account: current_account
    200
  end
  
  get '/comments/:id/unlike' do
    @comment = Comment.find(params[:id]) || not_found
    @commentable = @comment.commentable
    @comment.comment_likes.find_by(account: current_account).try(:destroy)
    200
  end    
  
  get '/posts/:id' do
    @post = Post.find(params[:id]) || not_found
    @commentable = @post.commentable
    partial :'comments/post', :locals => {:post => @post}
  end
  
  get '/posts/:id/unsubscribe' do
    @post = Post.find(params[:id]) || not_found
    @commentable = @post.commentable
    @post.subscriptions.find_by(account: current_account).try(:destroy)
    flash[:notice] = "You unsubscribed from the post"
    redirect back
    # redirect "/a/#{@group.slug}/#{@post.commentable_type.underscore.pluralize}/#{@post.commentable_id}#post-#{@post.id}"        
  end    
  
  get '/posts/:id/replies' do
    @post = Post.find(params[:id]) || not_found
    @commentable = @post.commentable
    partial :'comments/replies', :locals => {:post => @post}
  end  
    
  get '/comments/:id/options' do
    @comment = Comment.find(params[:id]) || not_found
    @commentable = @comment.commentable
    partial :'comments/options', :locals => {:comment => @comment}
  end
  
  post '/options/create' do
    @comment = Comment.find(params[:comment_id]) || not_found
    @comment.options.create!(account: current_account, text: params[:text])
    200   
  end  
  
  post '/options/:id/vote' do
    @option = Option.find(params[:id]) || not_found
    if params[:vote]
      @option.votes.create!(account: current_account)
    else
      @option.votes.find_by(account: current_account).try(:destroy)
    end
    200
  end  
  
  get '/options/:id/destroy' do
    @option = Option.find(params[:id]) || not_found
    @option.destroy
    redirect back
  end    
  
  get '/subscriptions/create' do
    @post = Post.find(params[:post_id]) || not_found
    @post.subscriptions.create!(account: current_account)
    200   
  end      
  
  get '/subscriptions/:id/destroy' do
    @subscription = Subscription.find(params[:id]) || not_found
    @subscription.destroy
    200        
  end
  
end