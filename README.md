곧 정식으로 릴리스될 예정인 레일스 5의 여러가지 추가 기능 중에 두 가지가 주목을 받고 있다. 하나는 `ActionCable`, 다른 하나는 `Turblinks 3`다. 
`ActionCable`에 대해서는 별도의 글을 준비 중이며, 여기서는 `Turbolinks 3`에 대해서 추가된 기능 중심으로 알아 보도록 하겠다. 

> 동영상 [New Turbolinks 3 Features With Ruby on Rails](https://www.livecoding.tv/video/new-turbolinks-3-features-with-ruby-on-rails/)

이번 `Turbolinks 3`에서 추가된 기능으로 `Partial Replacement`에 대한 내용을 샘플 애플리케이션과 함께 알아 보도록 하자. 

---

`Turbolinks`가 적용되는 링크를 클릭할 때 해당 링크로 접속한 후 렌더링되는 전체 페이지 중 `body` 부분의 컨텐츠만 현재 페이지의 `body`로 업데이트된다. 따라서 자바스크립트와 `CSS`를 포함한 전체 페이지가 리로드될 때보다 속도가 빨라지는 효과를 볼 수 있다. 

최근 버전 3로 업그레이드되면서 `pjax`와 같이 태그의 `id` 값을 근거로 특정 부분만 업데이트할 수 있는 기능을 제공하게 되었다. 

### 1. 샘플 애플리케이션의 생성

아래의 샘플 애플리케이션은 루비 v2.3.0, 레일스 v5.0.0.beta1 에서 작성하였다.
샘플 애플리케이션에서는 `Post` 모델을 `Comment` 모델과 일대다의 관계로 연결한다. 

```
$ rails new turbolinks3
```

### 2. Gem 추가

```
# Gemfile

gem 'font-awesome-rails'
gem 'bootstrap-sass'
gem 'simple_form'
gem 'turbolinks', github: 'rails/turbolinks'
```

이미 포하되어 있는 `turbolinks` 젬은 `github: 'rails/turbolinks'` 옵션을 추가한다. 

### 3. 번들 인스톨 및 젬 셋팅

```
$ bundle install
```

```
// app/assets/stylesheets/application.scss

@import "bootstrap-sprockets";
@import "bootstrap";
@import "bootstrap/theme";
@import "posts";
```

```
// app/assets/javascripts/application.js

//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require turbolinks
//= require_tree .
```

```
$ rails g simple_form:install --bootstrap
```

### 4. Post 리소스의 Scaffolding

```
$ rails g scaffold Post title content:text
```

### 5. Comment 모델의 생성

```
$ rails g model Comment post:references content:text
```

### 6. DB 마이그레이션 

```
$ rails db:migrate
```

### 7. Post 모델 클래스의 관계선언

```
class Post < ApplicationRecord
  has_many :comments, dependent: :destroy

  validates :title, presence: true
end
```

### 8. Comment 모델 클래스의 필수항목 지정

```
class Comment < ApplicationRecord
  belongs_to :post

  validates :content, presence: true
end
```

### 9. 중첩 라우트와 루트 라우트의 선언

```
root "posts#index"

resources :posts do 
  resources :comments 
end 
```

### 10. 스타일 커스터마이징

```
/* app/assets/stylesheets/posts.scss */

body { padding-top: 60px; }
.navbar-brand { color : darkred !important; font-weight: bold !important; }

/*
  Place all the styles related to the matching controller here.
  They will automatically be included in application.css.
*/

h1, h2, h3, h4, h5, h5 {
  margin-bottom:1em !important;
}

fieldset {
  border:1px solid #eaeaea !important;
  border-radius: 5px;
  padding-left: 1em !important;
  padding-right: 1em !important;
  margin-bottom: 1em;
}

legend  {
  display: inline !important;
  background: #eaeaea !important;
  padding-left:.5em !important;
  padding-right: .5em !important;
}

#comments {
  overflow: auto;
  margin-bottom: 1em !important;
  h2 {
    margin-bottom: .5em !important;
  }
}

.form-actions {
  border:1px solid #eaeaea;
  padding: 1em 1em 2em;
  background-color: #eeeeee;
  
}
```

### 11. 애플리케이션 레이아웃 파일의 변경

```
<-- app/views/layouts/application.html.erb -->

<!DOCTYPE html>
<html>
  <head>
    <title>FieldsForR5</title>
    <%= csrf_meta_tags %>
    <%= action_cable_meta_tag %>

    <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track' => true %>
    <%= javascript_include_tag 'application', 'data-turbolinks-track' => true %>
  </head>

  <body>

  <nav class="navbar navbar-default navbar-fixed-top">
    <div class="container">
      <div class="navbar-header">
        <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
          <span class="sr-only">Toggle navigation</span>
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
          <span class="icon-bar"></span>
        </button>
        <a class="navbar-brand" href="/">Turbolinks 3</a>
      </div>
      <div id="navbar" class="collapse navbar-collapse">
        <ul class="nav navbar-nav">
          <li class="active"><a href="#">Home</a></li>
          <li><a href="#about">About</a></li>
          <li><a href="#contact">Contact</a></li>
        </ul>
      </div><!--/.nav-collapse -->
    </div>
  </nav>

    <div class="container">
      <div class="row">
        <div class="col-md-12">
          <div id="flash_message">
            <%= flash_messages %>
          </div>
          <%= yield %>
        </div>
      </div>
    </div>

  </body>
</html>
```

### 12. Flash 메시지 헬퍼 메소드의 정의 

```
# app/helpers/application_helper.rb

module ApplicationHelper
  def bootstrap_class_for flash_type
    hash = HashWithIndifferentAccess.new({ success: "alert-success", error: "alert-danger", alert: "alert-warning", notice: "alert-info" })
    hash[flash_type] || flash_type.to_s
  end

  def flash_messages(opts = {})
    html_all = ""
    flash.each do |msg_type, message|
      html = <<-HTML
    <div class="alert #{bootstrap_class_for(msg_type)} alert-dismissable"><button type="button" class="close"
    data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
      #{message}
    </div>
      HTML
      html_all += html
    end
    html_all.html_safe
  end
end
```

### 13. Posts#Index 뷰 파일의 변경

```
<!-- app/views/posts/index.html.erb -->

<h1>Posts</h1>

<table class="table">
  <thead>
    <tr>
      <th class="col-md-8">Title</th>
      <th colspan="3"></th>
    </tr>
  </thead>

  <tbody>
    <% @posts.each do |post| %>
      <tr>
        <td><%= post.title %></td>
        <td><%= link_to 'Show', post %></td>
        <td><%= link_to 'Edit', edit_post_path(post) %></td>
        <td><%= link_to 'Destroy', post, method: :delete, data: { confirm: 'Are you sure?' } %></td>
      </tr>
    <% end %>
  </tbody>
</table>

<div class="form-actions">
  <%= link_to 'New Post', new_post_path, class:'btn btn-default' %>

</div>
```

### 14. Post 폼 파셜 파일 변경

```
<!-- app/views/posts/_form.html.erb -->

<%= simple_form_for(@post) do |f| %>
  <%= f.error_notification %>

  <div class="form-inputs">
    <%= f.input :title %>
    <%= f.input :content, input_html: { rows: 5 } %>
  </div>

  <div class="form-actions">
    <%= f.button :submit %>
    <%= link_to 'Show', @post, class:'btn btn-default' if @post.persisted? %>
    <%= link_to 'Back', posts_path, class: 'btn btn-default' %>
  </div>
<% end %>
```

### 15. Post#New 뷰 템플릿 파일의 변경

```
<!-- app/views/posts/new.html.erb -->

<h1>New Post</h1>

<%= render 'form', post: @post %>
```

### 16. Post#Edit 뷰 템플릿 파일의 변경

```
<!-- app/views/posts/edit.html.erb -->

<h1>Editing Post</h1>

<%= render 'form', post: @post %>
```


### 17. Posts#Show 뷰 파일의 변경

```
<!-- app/views/posts/show.html.erb -->

<h2>Post <small><%= action_name %></small></h2>

<fieldset>
  <legend>Post#<%= @post.id %></legend>
  <p>
    <strong>Title:</strong>
    <%= @post.title %>
  </p>

  <p>
    <strong>Content:</strong>
    <%= @post.content %>
  </p>
</fieldset>

<div class="text-right">
  <%= link_to 'Edit', edit_post_path(@post), class:'btn btn-default' %>
  <%= link_to 'Back', posts_path, class:'btn btn-default' %>
</div>

<div id="comments">
  <h2><%= pluralize @post.comments.count, "Comment" %></h2>

  <ul>
    <%= render @post.comments %>
  </ul>
  <%= render "comments/form", comment: @post.comments.build %>

</div>
```

### 18. Comments 폼 파셜의 생성

```
<!-- app/vews/comments/_form.html.erb -->

<%= simple_form_for [comment.post, comment], remote: true do |f| %>
  <%= f.input :content, label: 'Add a comment', input_html: { rows: 5 } %>
  <%= f.button :submit, class: 'pull-right' %>
<% end %>
```

### 19. Comment 뷰 파셜의 생성

```
<li>
  <%= comment.content %> (<%= link_to "x", [comment.post, comment], method: :delete, data:{confirm: "Are you sure?"}, remote: true %>)
</li>
```

### 20. Comments 컨트롤러의 생성

```
# app/controllers/comments_controller.rb

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
```


이상으로 20단계를 거쳐 `Turbolinks 3`의 데모를 구현할 수 있었다. 

소스 : https://github.com/luciuschoi/turbolinks3_sample
데모 : https://turbolinks3.herokuapp.com/
 
