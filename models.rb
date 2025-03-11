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

def projects_keyword(keyword)
  db = connect_db
  db.execute("
    SELECT *
    FROM ((project_tag_rel 
      INNER JOIN project ON project_tag_rel.projectid = project.id) 
      INNER JOIN tag ON project_tag_rel.tagid = tag.id) 
    WHERE public = 1 AND projectname LIKE ?", "%#{keyword}%")
end

def project_id(id)
  db = connect_db
  # § kolla om det är ens egna och i så fall spelar public ingen roll
  db.execute("SELECT * FROM project WHERE id = ? AND public = 1", id)[0]
end

def parts
  db = connect_db
  db.execute("SELECT * FROM part")
end

def parts_search(name, type) # TRASIGT
  db = connect_db
  name = '' if name.nil?
  type = '' if type.nil?

  if name.empty? && type.empty?
    db.execute("SELECT * FROM part")
  elsif name.empty?
    db.execute("SELECT * FROM part WHERE name LIKE ?", name)
  elsif type.empty?
    db.execute("SELECT * FROM part WHERE type LIKE ?", type)
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
