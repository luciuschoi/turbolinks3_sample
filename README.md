곧 정식으로 릴리스될 예정인 레일스 5의 여러가지 추가 기능 중에 두 가지가 주목을 받고 있다. 하나는 `ActionCable`, 다른 하나는 `Turbolinks 3`다. 
`ActionCable`에 대해서는 별도의 글을 준비 중이며, 여기서는 `Turbolinks 3`에 대해서 추가된 기능 중심으로 알아 보도록 하겠다. 

> 참고동영상 [New Turbolinks 3 Features With Ruby on Rails](https://www.livecoding.tv/video/new-turbolinks-3-features-with-ruby-on-rails/)

특히 `Turbolinks 3`에서 추가된 기능 중 `Partial Replacement`에 대한 내용을 샘플 애플리케이션과 함께 알아 보도록 하자. 

---

레일스 프로젝트를 생성하면 디폴트로 `Turbolinks`가 작동하게 된다. 따라서 페이지 내의 링크를 클릭할 때마다 해당 링크로 접속한 후 렌더링되는 전체 페이지 중 `body` 부분의 컨텐츠만 현재 페이지의 `body`로 업데이트된다. 따라서 자바스크립트와 `CSS`를 포함한 전체 페이지가 리로드될 때보다 속도가 빨라지는 효과를 볼 수 있다. 

최근 버전 3로 업그레이드되면서 `pjax`와 비슷한 기능을 구현할 수 있게 되었는데, 페이지 내의 특정 `id` 값을 가지는 태그의 컨텐츠만을 업데이트할 수 있는 기능을 제공하게 되었다. 

### 1. 샘플 애플리케이션의 생성

아래의 샘플 애플리케이션은 루비 v2.3.0, 레일스 v5.0.0.beta1 에서 작성하였다.

샘플 애플리케이션에서는 `Post` 모델을 `Comment` 모델과 일대다의 관계로 연결한다. `posts#show` 액션 뷰 파일 하단에 `comments`라는 `id` 값을 가지는 `div` 태그를 생성한 후, 이 안에서 기작성된 `comment` 객체들을 보여주고 `comment`를 입력하는 폼을 위치시킨다. 이 폼에 글을 입력하고 `submit`하면 `comments#create` 액션이 `ajax`로 호출된 후 현재 페이지로 리디렉트 되면서 `{change: 'comments'}` 옵션으로 지정된 부분만 업데이트 된다. 이것이 `Turbolinks 3: Partial Replacement` 기능의 대략적인 로직이다. 

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

> **주의** : [Rubygems.org](https://rubygems.org/gems/turbolinks) 젬 목록에는 3버전이 아직 배포되지 않았기 때문에, `github` 저장소 옵션을 추가해 주고 `bundle install`한다. `bundle list` 명령을 실행하여 인스톨 버전이 `turbolinks (3.0.0 dd31f4b)` 인지 확인한다.

### 3. 번들 인스톨 및 젬 셋팅

```
$ bundle install
```

`app/assets/stylesheets/application.css`파일의 확장명을 `.scss` 파일로 변경하여 `sassy CSS`로 작성할 수 있도록 한다. 

```
// app/assets/stylesheets/application.scss

@import "bootstrap-sprockets";
@import "bootstrap";
@import "bootstrap/theme";
@import "posts";
```

> **주의** : 레일스 5.0.0.beta1 버전에서 `scaffolding`으로 생성된 스타일시트 파일명의 확장자는 이전 버전과는 달리 `.css`로 지정되기 때문에, `posts.css` 파일을 `posts.scss`로 변경한다. 

자바스크립트 `manifest` 파일인 `app/assets/javascripts/application.js` 파일에는 `bootstrap-sprocket`를 추가해서 `Bootstrap`이 동작하도록 해 준다. 

```
// app/assets/javascripts/application.js

//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require turbolinks
//= require_tree .
```

`simple_form` 젬이 동작하기 위해서 아래와 같은 설치 명령을 실행해야 한다. 이 때 `Bootstrap` 스타일을 적용하기 위해서 `--bootstrap` 옵션을 반드시 지정해 주어야 한다. 

```
$ rails g simple_form:install --bootstrap
```

### 4. Post 리소스의 Scaffolding

`scaffolding` 제너레이터를 이용하여...

```
$ rails g scaffold Post title content:text
```

### 5. Comment 모델의 생성

`model` 제너레이터를 이용하여...

```
$ rails g model Comment post:references content:text
```

### 6. DB 마이그레이션 

실제로 DB 테이블을 생성하기 위해서 `db:migrate` 작업을 해 준다. 

```
$ rails db:migrate
```

### 7. Post 모델 클래스의 관계선언

`app/models/post.rb` 파일을 열고 `comments` 리소스와의 관계선언을 `has_many`로 지정해 준다. 또한 `title` 속성을 필수항목으로 지정해 준다. 

```
class Post < ApplicationRecord
  has_many :comments, dependent: :destroy

  validates :title, presence: true
end
```

### 8. Comment 모델 클래스의 필수항목 지정

`app/models/comment.rb` 파일을 열고 `content` 속성을 필수항목으로 지정해 준다. 

```
class Comment < ApplicationRecord
  belongs_to :post

  validates :content, presence: true
end
```

### 9. 중첩 라우트와 루트 라우트의 선언

이제 루트 라우트와 두 리소스의 중첩 라우팅을 추가해 준다. 

```
root "posts#index"

resources :posts do 
  resources :comments 
end 
```

### 10. 스타일 커스터마이징

약간의 스타링을 추가하기 위해 아래와 같이 `posts.scss`파일을 업데이트한다. 

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

애플리케이션 레이아웃을 아래와 같이 변경한다. 9번째 코드라인은 스마트 디바이스에서 접속할 때 반응형으로 보이도록 하기 위한 것이다. 

```
<-- app/views/layouts/application.html.erb -->

<!DOCTYPE html>
<html>
  <head>
    <title>FieldsForR5</title>
    <%= csrf_meta_tags %>
    <%= action_cable_meta_tag %>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
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

41번 코드라인의 `flash_messages` 메소드는 레일스의 `flash` 메시지를 `Bootstrap` 스타일을 이용하여 보이도록 별도의 헬퍼 메소드를 작성하여 사용하였다.

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

`Table` 태그에 `Bootstrap`용 클래스인 `table`을 추가해 준다(5번 코드라인). 26번 코드라인에서는 링크에 버튼 스타일을 클래스로 지정한다.  

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

8번 코드라인에서 `textarea` 행 수를 5개로 지정하고, 폼 관련 링크버튼을 일관성있게 보이도록 13, 14번 코드라인을 추가한다. 

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

링크 버튼을 폼 파셜로 이동한다. 

```
<!-- app/views/posts/new.html.erb -->

<h1>New Post</h1>

<%= render 'form', post: @post %>
```

### 16. Post#Edit 뷰 템플릿 파일의 변경

링크 버튼을 폼 파셜로 이동한다. 
```
<!-- app/views/posts/edit.html.erb -->

<h1>Editing Post</h1>

<%= render 'form', post: @post %>
```

### 17. Posts#Show 뷰 파일의 변경

23~31 코드라인에 걸쳐 이미 작성된 `comment` 객체들을 보여주고 새로운 `comment`를 입력할 수 있는 폼을 추가해 준다. 

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

`app/views/comments` 폴더를 생성하고 `_form.html.erb` 파일을 추가한 후 아래와 같이 코드를 작성한다. 

```
<!-- app/views/comments/_form.html.erb -->

<%= simple_form_for [comment.post, comment], remote: true do |f| %>
  <%= f.input :content, label: 'Add a comment', input_html: { rows: 5 } %>
  <%= f.button :submit, class: 'pull-right' %>
<% end %>
```

### 19. Comment 뷰 파셜의 생성

이미 작성된 `comment`들을 보여 주기 위한 `_comment.html.erb` 파셜 파일을 아래와 같이 작성한다.

```
<!-- app/views/comments/_comment.html.erb -->

<li>
  <%= comment.content %> (<%= link_to "x", [comment.post, comment], method: :delete, data:{confirm: "Are you sure?"}, remote: true %>)
</li>
```

### 20. Comments 컨트롤러의 생성

`controller` 제너레이터를 이용하여 `comments` 컨트롤러를 생성한다. 이 때 `create`와 `destroy` 액션도 생성되도록 추가해 준다. 

```
$ rails g controller comments create destroy
```

각 액션에 아래와 같이 코드를 작성해 준다. 

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

12, 23번 코드라인이 바로 `Turbolinks 3`에서 새로 도입한 `Partial Replacement`가 동작하게 해 준다. `changes` 옵션에 지정하는 문자열은 태그의 `id` 값을 의미한다. 따라서 각 액션에 대한 `remote(ajax)` 호출이 있은 후 이 두개의 `id`를 가지는 `div` 태그의 컨텐츠를 업데이트해 주게 된다.

이상으로 20단계를 거쳐 `Turbolinks 3`의 데모를 구현할 수 있었다. 

---


소스 : https://github.com/luciuschoi/turbolinks3_sample
데모 : https://turbolinks3.herokuapp.com/
 
