require 'sqlite3'

db = SQLite3::Database.open 'Library_new.db'
db_new = SQLite3::Database.open 'Library.db'

result=db.query("Select * from books")



  while (first_result = result.next) do
      result1=first_result[6]
      # result1.gsub!("/","\\")
      first_result[6]=result1[59..result1.length]

      db_new.execute "insert into books (Id,Author,Name,Genre,Year,Read,Filename,Rating) values(?,?,?,?,?,?,?,?)", first_result

  end


# /media/bivan/9e0c31fb-f991-49da-82db-9b5adf1ad62a/ivan/fb2/Серия - Секретный фарватер/Молчанов. Побег обреченных.fb2
# d:\document\fb2\Bestseller
