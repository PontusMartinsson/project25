def connect_db
  db = SQLite3::Database.new('db/greja.db')
  db.results_as_hash = true
  db
end

def connect_db_nohash
  SQLite3::Database.new('db/greja.db')
end

def db_get(column, table, hash = false)
  db = hash ? connect_db : connect_db_nohash
  db.execute("SELECT #{column} FROM #{table}").flatten
end

def admin?
  session[:admin] == 1
end

def create_user(username, password)
  db = connect_db_nohash
  passworddigest = BCrypt::Password.create(password)
  db.execute("INSERT INTO user (username, password, admin) VALUES (?, ?, 0)", [username, passworddigest])
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
  if id.to_i == session[:id] || admin?
    db.execute("SELECT *
    FROM ((project_tag_rel
    INNER JOIN project ON project_tag_rel.projectid = project.id)
    INNER JOIN tag ON project_tag_rel.tagid = tag.id) 
    WHERE userid = ?", id)
  else
    db.execute("SELECT *
    FROM ((project_tag_rel
    INNER JOIN project ON project_tag_rel.projectid = project.id)
    INNER JOIN tag ON project_tag_rel.tagid = tag.id) 
    WHERE userid = ? AND public = 1", id)
  end
end

def sql_add(sql, operator, phrase)
  sql[-1] == '?' || sql[-1] == ')' ? sql << " #{operator} #{phrase}" : sql << " #{phrase}"
end

def keyword_nil(keyword)
  keyword.nil? || keyword.empty? ? '' : keyword.insert(0, '%') << '%'
end

def projects_search(name, creator, tag) # § fixa bara public
  db = connect_db_nohash

  name = keyword_nil(name)
  creator = keyword_nil(creator)
  tag = keyword_nil(tag)

  sql = ""

  vars = []

  unless name.empty? && creator.empty? && tag.empty?
    unless tag.empty? # filter på tag
      tagid = db.execute("SELECT id FROM tag WHERE tagname LIKE ?", tag).flatten

      if tagid.empty?
        return []
      else
        sql = "
          SELECT *
          FROM ((project_tag_rel
            INNER JOIN project ON project_tag_rel.projectid = project.id)
            INNER JOIN tag ON project_tag_rel.tagid = tag.id)
          WHERE ("

        tagid.each do |i|
          sql_add(sql, "OR", "tagid = ?")
          vars.append i
        end

        sql << ")"
      end
    end

    unless name.empty? # filter på projekttitel
      if sql.empty?
        sql = "SELECT *
          FROM ((project_tag_rel
            INNER JOIN project ON project_tag_rel.projectid = project.id)
            INNER JOIN tag ON project_tag_rel.tagid = tag.id) 
            WHERE"
      end
      sql_add(sql, "AND", "projectname LIKE ?")
      vars.append(name)
    end

    unless creator.empty? # filter på skapares namn
      if sql.empty?
        sql = "SELECT *
          FROM ((project_tag_rel
            INNER JOIN project ON project_tag_rel.projectid = project.id)
            INNER JOIN tag ON project_tag_rel.tagid = tag.id) 
            WHERE"
      end
      id = db.execute("SELECT id FROM user WHERE username LIKE ?", creator)
      sql_add(sql, "AND", "userid = ?")
      id.empty? ? vars.append(nil) : vars.append(id)
    end
  end

  db.results_as_hash = true

  if sql.empty?
    sql = "SELECT *
    FROM ((project_tag_rel
    INNER JOIN project ON project_tag_rel.projectid = project.id)
    INNER JOIN tag ON project_tag_rel.tagid = tag.id) WHERE"
  end
  
  sql_add(sql, "AND", "public = 1")
  
  db.execute(sql, vars)
end

def project_id(id)
  db = connect_db

  if session[:admin] == 1
    db.execute("SELECT *
    FROM ((project_tag_rel
    INNER JOIN project ON project_tag_rel.projectid = project.id)
    INNER JOIN tag ON project_tag_rel.tagid = tag.id) 
    WHERE projectid = ?", id)
  else
    db.execute("SELECT *
    FROM ((project_tag_rel
    INNER JOIN project ON project_tag_rel.projectid = project.id)
    INNER JOIN tag ON project_tag_rel.tagid = tag.id) 
    WHERE projectid = ? AND (public = 1 OR userid = ?)", [id, session[:id]])
  end
end

def parts_project(id)
  db = connect_db_nohash
  part_ids = db.execute("SELECT part1, part2, part3 FROM project WHERE id = ?", id)
  db.execute("SELECT name FROM part WHERE id = ? OR id = ? OR id = ?", part_ids).flatten
end

def create_project(params)
  db = connect_db

  public = params['public'].nil? ? 0 : 1

  db.execute("INSERT INTO project 
    (projectname, userid, public, part1, part2, part3, tags) 
    VALUES 
    (?, ?, ?, ?, ?, ?, ?)
    ", [params['name'], session[:id], public, params['part1'].to_i, params['part2'].to_i, params['part3'].to_i, params['tags']])
  
  tags = params['tags'].split(' ')
  
  db.results_as_hash = false
  existing_tags = db.execute("SELECT tagname FROM tag").flatten
  project_id = db.execute("SELECT id FROM project WHERE projectname = ?", params['name']).first

  tags.each do |tag|
    unless existing_tags.include?(tag)
      db.execute("INSERT INTO tag (tagname) VALUES (?)", tag)
    end

    tag_id = db.execute("SELECT id FROM tag WHERE tagname = ?", tag).first

    db.execute("INSERT INTO project_tag_rel (projectid, tagid) VALUES (?, ?)", [project_id, tag_id])
  end
end

def parts_search(name, type)
  db = connect_db

  name = keyword_nil(name)
  type = keyword_nil(type)

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

def create_part(name, type)
  db = connect_db
  db.execute("INSERT INTO part (name, type) VALUES (?, ?)", [name, type])
end

def verify_part_creation(name, type)
  (db_get('name', 'part').include?(name) && part_type(name).include?(type))
end

def remove_duplicates(data)
  seen = []
  output = []
  data.each do |project|
    unless seen.include?(project['projectid'])
      output.append(project)
      seen.append(project['projectid'])
    end
  end
  output
end

def verify_ownership(projectid)
  db = connect_db_nohash

  userid = db.execute("SELECT userid FROM project WHERE id = ?", projectid).first.first
  userid == session[:id] || admin?
end

def delete_project(projectid)
  db = connect_db
  db.execute("DELETE FROM project WHERE id = ?", projectid)
  db.execute("DELETE FROM project_tag_rel WHERE projectid = ?", projectid)
end
