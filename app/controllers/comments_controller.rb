class CommentsController < ApplicationController
  def create
    post = Post.find(params[:post_id])
    comment = post.comments.build(comment_params)
    if comment.save
      flash[:notice] = "Successfully saved!"
    else
      flash[:error] = "Validation error! : you should type at least a character in comment."
    end
    redirect_to post, { change: ["comments", "flash_message"] }
  end
  def destroy
    post = Post.find(params[:post_id])
    comment = post.comments.find(params[:id])
    if comment.destroy
      flash[:notice] = "Successfully deleted!"
    else
      flash[:error] = "Error! : it could not be deleted."
    end
    redirect_to post, { change: ["comments", "flash_message"] }
  end
  private
  def comment_params
    params.require(:comment).permit(:post_id, :content)
  end
end