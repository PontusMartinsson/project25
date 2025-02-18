def connect_db
  db = SQLite3::Database.new('db/greja.db')
  db.results_as_hash = true
  db
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
  db.execute("SELECT * FROM project WHERE userid = ? and public = 1", id)
end

def projects_keyword(keyword)
  db = connect_db
  db.execute("
    SELECT *
    FROM ((project_tag_rel 
      INNER JOIN project ON project_tag_rel.projectid = project.id) 
      INNER JOIN tag ON project_tag_rel.tagid = tag.id) 
    WHERE public = 1 and projectname LIKE ?", "%#{keyword}%")
end

def project_id(id)
  db = connect_db
  # § kolla om det är ens egna och i så fall spelar public ingen roll
  db.execute("SELECT * FROM project WHERE id = ? and public = 1", id)[0]
end