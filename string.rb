require 'find'
require 'Nokogiri'
require 'gtk3'
require 'sqlite3'

Gtk.init
db = SQLite3::Database.open 'Library_new.db'
unless db.errcode
  print "Database error code-",db.errcode,"\n";
  print "Database error msg-",db.errmsg,"\n";
end

window = Gtk::Window.new("Toplevel")
window.signal_connect("destroy") { Gtk.main_quit }
button=Gtk::Button.new();
button.set_label("open")
window.add(button)
button.signal_connect('clicked'){
dialog = Gtk::FileChooserDialog.new(:title => "Open File",
                                     :action => :select_folder,
                                     :buttons => [[Gtk::Stock::OPEN, :accept],
                                                 [Gtk::Stock::CANCEL, :cancel]])


if dialog.run == :accept
pdf_file_paths = []
Find.find(dialog.filename) do |path|
  pdf_file_paths << path if path =~ /.*\.fb2$/
end
for i in 0..pdf_file_paths.size-1 do
 doc=Nokogiri::XML(open(pdf_file_paths[i]))
author=""
  if  doc.css("title-info author last-name").first then  author+= doc.css("title-info author last-name").first.content+" " end
      if  doc.css("title-info author middle-name").first then  author+= doc.css("title-info author middle-name").first.content + " " end
  if  doc.css("title-info author first-name").first then  author+= doc.css("title-info author first-name").first.content end


  if  doc.css("title-info genre").first
    genres=""
    doc.css("title-info genre").each do |genre|
     genres+=genre.content+" "
   end
   end
   if  doc.css("title-info book-title").first then  b_title = doc.css("title-info book-title").first.content end
   if  doc.css("title-info date").first then  b_date = doc.css("title-info date").first.content end

db.execute "insert into books (Id,Author,Name,Genre,Year,Read,Filename,Rating) values(?,?,?,?,?,0,?,0)", i,author,b_title,genres,b_date,pdf_file_paths[i]
end
end


dialog.destroy
}

  window.add(button)
  window.show_all
  Gtk.main
