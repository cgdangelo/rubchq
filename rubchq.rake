require 'basecamp'

namespace :rubchq do
  desc "Push commits to Basecamp resources."
  task :push do 
    login
    projects

    current_project = get_current_project
    puts "* Using project ##{current_project[0]} \"#{current_project[1]}\""

    puts "* Resource type: (t)odo, (m)essage?"
    resource_type = STDIN.gets.chomp

    case resource_type
    when "t"
      puts "* Fetching todo items for project..."
      todos = get_todo_items_on_project(current_project[0])
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

  todo_items
end
