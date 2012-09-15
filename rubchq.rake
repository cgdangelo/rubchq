require 'basecamp'

namespace :rubchq do
  desc "Push commits to Basecamp resources."
  task :push, :sha do |t, args|
    sha = args[:sha] || 'HEAD'
    commit_msg = `git --no-pager log --date=rfc -1 #{sha}`.chomp
    
    login

    resource_info = get_resource_from_commit(sha) || get_resource_from_user

    case resource_info[0]
    when "m"
      add_comment_to_message(resource_info[1], commit_msg)
    when "t"
      add_comment_to_todo_item(resource_info[1], commit_msg)
    when "ms"
      add_comment_to_milestone(resource_info[1], commit_msg)
    end

  end
end

def login
  url = `git config rubchq.url`.chomp
  secure = `git config rubchq.ssl`.chomp
  key = `git config rubchq.key`.chomp

  Basecamp.establish_connection!(url, key, '', secure)
end

def projects
  projects = []
  Basecamp::Project.find(:all).each do |project|
    projects << [project.id.to_s, project.name]
  end

  projects.sort! {|a,b| a[1].downcase <=> b[1].downcase}
end

def get_current_project
  project = `git config rubchq.project`.chomp
  if project.empty? then
    index = 1
    projects.each do |id, name|
      puts "(#{index}) #{name} [##{id}]"
      index += 1
    end

    print "* Enter 1 - #{index}: "
    picked_project = STDIN.gets.chomp.to_i - 1

    projects[picked_project]
  else
    configured_project = Basecamp::Project.find(project)
    [configured_project.id.to_s, configured_project.name]
  end
end

def get_todo_items_on_project(project)
  todo_items = []
  todo_lists = Basecamp::TodoList.find(:all, :params => { :project_id => project })
  todo_lists.each do |todo_list|
    todo_items << Basecamp::TodoItem.find(:all, :params => { :todo_list_id => todo_list.id})
  end

  todo_items.flatten
end

def get_messages_on_project(project)
  Basecamp::Message.find(:all, :params => { :project_id => project })
end

def get_resource_from_commit(sha)
  /bc(\w+)#(\d+)/.match(`git --no-pager log -1 --format=%B #{sha}`).to_a.slice(1,2)
end

def get_resource_from_user
  resource_info = []

  current_project = get_current_project
  puts "* Using project ##{current_project[0]} \"#{current_project[1]}\""

  puts "* Resource type: (t)odo, (m)essage?"
  resource_type = STDIN.gets.chomp

  case resource_type
  when "t"
    puts "* Fetching todo items for project..."
    resources = get_todo_items_on_project(current_project[0])
    resource_info[0] = "t"
  when "m"
    puts "* Fetching messages for project..."
    resources = get_messages_on_project(current_project[0])
    resource_info[0] = "m"
  end

  index = 1
  resources.each do |resource|
    title = resource.title || resource.content
    puts "(#{index}) \"#{title}\" by #{resource.author_name} [##{resource.id}]"
  end
end

def add_comment_to_message(resource_id, msg)
  comment = Basecamp::Comment.new(:post_id => resource_id, :use_textile => 1)
  comment.body = "<pre>" + msg + "</pre>"
  comment.save
end

def add_comment_to_todo_item(resource_id, msg)
  comment = Basecamp::Comment.new(:todo_item_id => resource_id, :use_textile => 1)
  comment.body = "<pre>" + msg + "</pre>"
  comment.save
end

def add_comment_to_milestone(resource_id, msg)
  comment = Basecamp::Comment.new(:milestone_id => resource_id, :use_textile => 1)
  comment.body = "<pre>" + msg + "</pre>"
  comment.save
end
