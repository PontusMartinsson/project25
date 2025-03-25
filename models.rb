def connect_db
  db = SQLite3::Database.new('db/greja.db')
  db.results_as_hash = true
  db
end

def connect_db_nohash
  SQLite3::Database.new('db/greja.db')
end

def projects_public
  db = connect_db
  db.execute("
    SELECT *
    FROM ((project_tag_rel 
      INNER JOIN project ON project_tag_rel.projectid = project.id) 
      INNER JOIN tag ON project_tag_rel.tagid = tag.id) 
    WHERE public = 1
  ")
end

def projects_user(id)
  db = connect_db
  # § kolla om det är ens egna och i så fall spelar public ingen roll
  db.execute("SELECT * FROM project WHERE userid = ? AND public = 1", id)
end

# def projects_search(name, creator, tag)
#   db = connect_db

#   name = name.nil? || name.empty? ? '' : name.insert(0, '%') << '%'
#   creator = creator.nil? || creator.empty? ? '' : creator.insert(0, '%') << '%'
#   tag = tag.nil? || tag.empty? ? '' : tag.insert(0, '%') << '%'

#   sql = "SELECT * FROM project"
#   keywords = []

#   unless name.empty? && creator.empty? && tag.empty?
#     sql << " WHERE"
#     sql, keywords = add_to_sql(sql, keywords, name, 'projectname')
#     sql, keywords = add_to_sql(sql, keywords, creator, 'creator')
#     sql, keywords = add_to_sql(sql, keywords, tag, 'tag')
#   end

#   db.execute(sql, keywords)
# end

# def add_to_sql(sql, keywords, var, column)
#   unless var.empty?
#     if sql[-1] == '?'
#       sql << ' AND'
#     end
#     sql << " #{column} LIKE ?"
#     keywords.append(var)
#   end
#   return sql, keywords
# end

def projects_search(name, creator, tag)
  db = connect_db

  name = name.nil? || name.empty? ? '' : name.insert(0, '%') << '%'
  creator = creator.nil? || creator.empty? ? '' : creator.insert(0, '%') << '%'
  tag = tag.nil? || tag.empty? ? '' : tag.insert(0, '%') << '%'

  sql = "SELECT * FROM project"
  vars = []

  unless name.empty? && creator.empty? && tag.empty?
    sql << " WHERE"
    unless name.empty?
      sql << ' projectname LIKE ?'
      vars.append(name)
    end
    unless creator.empty?
      id = db.execute("SELECT id FROM user WHERE username LIKE ?", creator).first['id']
      sql[-1] == '?' ? sql << ' AND userid = ?' : sql << ' userid = ?'
      vars.append(id)
    end
    # unless tag.empty # hitta projekt med tag LIKE tag
    # end
  end

  p sql, vars
  db.execute(sql, vars)
end

def project_id(id)
  db = connect_db
  # § kolla om det är ens egna och i så fall spelar public ingen roll
  db.execute("SELECT * FROM project WHERE id = ? AND public = 1", id).first
end

def parts
  db = connect_db
  db.execute("SELECT * FROM part")
end

def parts_search(name, type)
  db = connect_db

  name = name.nil? || name.empty? ? '' : name.insert(0, '%') << '%'
  type = type.nil? || type.empty? ? '' : type.insert(0, '%') << '%'

  if name.empty? && type.empty?
    db.execute("SELECT * FROM part")
  elsif name.empty?
    db.execute("SELECT * FROM part WHERE type LIKE ?", type)
  elsif type.empty?
    db.execute("SELECT * FROM part WHERE name LIKE ?", name)
  else
    db.execute("SELECT * FROM part WHERE name LIKE ? AND type LIKE ?", [name, type])
  end
end

def part_type(name)
  db = connect_db_nohash
  db.execute("SELECT type FROM part WHERE name = ?", name).flatten
end

def part_names
  db = connect_db_nohash
  db.execute("SELECT name FROM part").flatten
end

def create_part(name, type)
  db = connect_db
  db.execute("INSERT INTO part (name, type) VALUES (?, ?)", [name, type])
end

def verify_part_creation(name, type)
  !(part_names.include?(name) && part_type(name).include?(type))
end
