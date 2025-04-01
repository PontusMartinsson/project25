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

def sql_add(sql, operator, phrase)
  sql[-1] == '?' || sql[-1] == ')' ? sql << " #{operator} #{phrase}" : sql << " #{phrase}"
end

def keyword_nil(keyword)
  keyword.nil? || keyword.empty? ? '' : keyword.insert(0, '%') << '%'
end

def projects_search(name, creator, tag)
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
        sql = "SELECT * FROM project WHERE"
      end
      sql_add(sql, "AND", "projectname LIKE ?")
      vars.append(name)
    end

    unless creator.empty? # filter på skapares namn
      if sql.empty?
        sql = "SELECT * FROM project WHERE"
      end
      id = db.execute("SELECT id FROM user WHERE username LIKE ?", creator)
      sql_add(sql, "AND", "userid = ?")
      id.empty? ? vars.append(nil) : vars.append(id)
    end

  end

  puts sql, vars
  db.results_as_hash = true
  sql.empty? ? db.execute("SELECT * FROM project") : db.execute(sql, vars)
end

def project_id(id)
  db = connect_db
  # § kolla om det är ens egna och i så fall spelar public ingen roll
  db.execute("SELECT * FROM project WHERE id = ? AND public = 1", id).first
end

def create_project(params)
  db = connect_db

  public = params['public'].nil? ? 0 : 1

  db.execute("INSERT INTO project 
    (projectname, userid, public, part1, part2, part3) 
    VALUES 
    (?, ?, ?, ?, ?, ? )
    ", [params['name'], 1, public, params['part1'].to_i, params['part2'].to_i, params['part3'].to_i]) # § fixa user id
end

def project_names
  db = connect_db_nohash
  db.execute("SELECT projectname FROM project").flatten
end

def parts
  db = connect_db
  db.execute("SELECT * FROM part")
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

def part_names
  db = connect_db_nohash
  db.execute("SELECT name FROM part").flatten
end

def create_part(name, type)
  db = connect_db
  db.execute("INSERT INTO part (name, type) VALUES (?, ?)", [name, type])
end

def verify_part_creation(name, type)
  (part_names.include?(name) && part_type(name).include?(type))
end
