
require "gtk3"
require 'sqlite3'
require "nokogiri"
require "Base64"
require "find"
ScreenX,ScreenY=1400,1100



def ReadInfoBook (fb2_filename, bufferBook, image1,labelpage,pagenum=1)

  unless (File.exist?(fb2_filename))
    bufferBook.text="File not find";

    labelpage.set_markup('<b>0</b> of <b>0</b>');
    return 1
  end
  doc=Nokogiri::XML(open(fb2_filename))
  if  doc.css("title-info author last-name").first then  l_name = doc.css("title-info author last-name").first.content end
  if  doc.css("title-info author first-name").first then  f_name = doc.css("title-info author first-name").first.content end
  if  doc.css("title-info author middle-name").first then  m_name = doc.css("title-info author middle-name").first.content end
  if  doc.css("title-info genre").first
    genres=""
    doc.css("title-info genre").each do |genre|
      genres+=genre.content+" "
    end
  end
  if  doc.css("title-info book-title").first then  b_title = doc.css("title-info book-title").first.content end
  if  doc.css("title-info annotation").first then  annotation = doc.css("title-info annotation").first.content end
  if  doc.css("title-info date").first then  b_date = doc.css("title-info date").first.content end
  bufferBook.text="";

  bufferBook.insert(bufferBook.start_iter,sprintf("%s %s %s \n",f_name,m_name,l_name),options={:tags=>[Tag_center,Tag_bold,Tag_size_big]});
  bufferBook.insert(bufferBook.end_iter,sprintf("%s \n %s \n\n",b_title,b_date),options={:tags=>[Tag_center,Tag_bold,Tag_size_big]});
  bufferBook.insert(bufferBook.end_iter,"Аннотация \n",options={:tags=>[Tag_center,Tag_bold,Tag_backcolor,Tag_size_big]});
  bufferBook.insert(bufferBook.end_iter,annotation,options={:tags=>[Tag_left,Tag_size] });
  bufferBook.insert(bufferBook.end_iter,"Путь к файлу \n\n",options={:tags=>[Tag_center,Tag_bold,Tag_backcolor]});
  bufferBook.insert(bufferBook.end_iter,fb2_filename,options={:tags=>[Tag_left]});
  if  doc.css("binary").first
    loader = GdkPixbuf::PixbufLoader.new()
    binary = Base64.decode64(doc.css("binary")[pagenum-1].content);
    loader.write(binary)
    loader.close
    pixbuf = loader.pixbuf
    # binary_from_frb = doc.css("binary").first.content
    h = pixbuf.height
    w = pixbuf.width
    w_pb=h_pb=ScreenY-450;
    if (w>h)
      h_pb=h*w_pb/w
    else
      w_pb=w*h_pb/h
    end
    image1.pixbuf=pixbuf.scale(w_pb,h_pb)
    max=doc.css("binary").size
    labelpage.set_markup('<b>'+pagenum.to_s+'</b> of <b>'+max.to_s+'</b>');
  end
end

def updateBD(database,num,column,record)
  database.execute "Update books set "+column+"=? where Id=?", record , num
  unless database.errcode
    print "Database error code-",database.errcode,"\n";
    print "Database error msg-",database.errmsg,"\n";
  end
end

def updatelist (liststore,database,query)

  queryString="select distinct * from books where (Author like '%"+query+"%'
or  Name like '%"+query+"%'
or  Genre like '%"+query+"%'
or  Filename like '%"+query+"%')"
  result=database.query(queryString)
  liststore.clear;
  while (first_result = result.next) do
      iter1=liststore.append()
      for i in 0...$columns_size
        if (i==0 || i==7 || i==5)
          iter1[i]=first_result[i].to_i
        else
          iter1[i]=first_result[i].to_s
        end

      end
    end
  end

  def onClickButtonRescan (par_win)

    open_dialog = Gtk::FileChooserDialog.new(:title =>'Pick File',:parent => par_win,:action => :select_folder,
                                             :buttons => [[Gtk::Stock::OPEN, Gtk::ResponseType::ACCEPT],
                                                          [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL]])


    if open_dialog.run == Gtk::ResponseType::ACCEPT
      puts "filename = #{open_dialog.filename}"
      puts "uri = #{open_dialog.uri}"
      open_dialog.close;
    else
      open_dialog.close;
    end


  end

  Gtk.init



  root_dir=''
  # root_dir='D:/document/fb2/'
  # root_dir="Smit_Zapretnyy-rayon.fb2 "


  db = SQLite3::Database.open 'Library.db'
  unless db.errcode
    print "Database error code-",db.errcode,"\n";
    print "Database error msg-",db.errmsg,"\n";
  end

  window = Gtk::Window.new("Toplevel")
  window.title = "My Home Library"
  window.override_background_color('normal',"#FFE7AF")




  #my @ScreenSize=`xrandr --current`;

  window.set_default_size(ScreenX-180,ScreenY-140)
  window.position='center'
  window.border_width=10
  window.signal_connect("destroy") { Gtk.main_quit }



  columns= ["Num","Autor","Name of Book","Genre","Year","Read","Filename","Rating"];
  $columns_size = columns.size


  liststore=Gtk::ListStore.new(Integer,String,String,String,String,Integer,String,Integer);




  list_of_books=Gtk::TreeView.new(liststore)
  list_of_books.columns_autosize
  find = Gtk::Entry.new();
  find.signal_connect("activate") {
    list_of_books.selection.unselect_all;
    updatelist(liststore,db,find.text)
  };
  for i  in 0...$columns_size do
      ##Reads column
      if (i==5)
        cell=Gtk::CellRendererToggle.new()
        cell.signal_connect('toggled') { |cell1,path|
          treeselection=list_of_books.selection
          if treeselection.selected[5]
            status1=1-liststore.get_value(treeselection.selected,5)
            num=liststore.get_value(treeselection.selected,0)
            liststore.set_value(treeselection.selected,5,status1)
            # запись в БД значения status в Read
            updateBD(db,num,"Read",status1)
          end
        }
        col=Gtk::TreeViewColumn.new(columns[i],cell,:active=>i);
        list_of_books.append_column(col); next;
      end
      ##rate column
      if (i==7)
        cell=Gtk::CellRendererPixbuf.new();
        col=Gtk::TreeViewColumn.new(columns[i],cell)
        col.set_sort_column_id(i);
        col.set_cell_data_func(cell) {
          |column, cell, model,iter|
          rating=model.get_value(iter, 7);
          file_of_rating="Rate"+rating.to_s+".png"
          pixbuf=GdkPixbuf::Pixbuf.new(:file=>file_of_rating,:width=>100,:height=>20)
          cell.pixbuf=pixbuf;
        }
        list_of_books.append_column(col); next;
      end


      cell=Gtk::CellRendererText.new();
      col=Gtk::TreeViewColumn.new(columns[i],cell,:text=>i);
      col.resizable=true;
      col.set_sizing('FIXED')
      case i
      when 1 then   col.fixed_width = 225
      when 2 then  col.fixed_width = 570
      when 3 then   col.fixed_width = 233
      when 4 then   col.fixed_width = 122
      end

      col.set_sort_column_id(i);


      if (i==0)||(i==6) then col.visible=false end;
      list_of_books.append_column(col);

    end



    scrollwindowTreeBook=Gtk::ScrolledWindow.new();
    scrollwindowTreeBook.set_min_content_height(190);
    scrollwindowTreeBook.set_policy('automatic','automatic');
    scrollwindowTreeBook.add(list_of_books);
    scrollwindowTreeBook.set_max_content_width(190);




    image=Gtk::Image.new();

    imageRate=Gtk::Image.new();
    imageRate.set_from_file("Rate.png");


    event_box=Gtk::EventBox.new();
    event_box.signal_connect('button-press-event') { |widgent,event|
      #Обработка рейтинга
      width1=(ScreenX-180)/2-20;
x0=(width1-500)/2;
      first_x=((event.x-x0)/100+1);
rate=sprintf("%d",first_x).to_i;
rate=5 if rate>5
rate=0 if rate<0;
imageRate.set_from_file("Rate"+rate.to_s+".png");
# updateBD(database,num,column,record)
# my $query_string="update books set read=1, rating=".$rate." where Id=".$model->get_value($iter,0);
select1=list_of_books.selection
iter=select1.selected
liststore.set_value(iter,7,rate);
liststore.set_value(iter,5,1);
}
event_box.add(imageRate);

event_box1=Gtk::EventBox.new();
event_box1.signal_connect('button-press-event') {onMouseClickImage=true};
event_box1.add(image);

##~ $imageRate.signal_connect('button-press-event',sub{print "Click"});

labelpage=Gtk::Label.new();
labelpage.set_markup('<b>1</b> of <b>1</b>');
labelpage.set_justify('center');
labelpage.set_line_wrap(false);


textBook=Gtk::TextView.new();
bufferBook=Gtk::TextBuffer.new();
Tag_bold=bufferBook.create_tag("bold",:weight=>1000);
Tag_center=bufferBook.create_tag("center",:justification=>'center');
Tag_left=bufferBook.create_tag("left",:justification=>'left');
Tag_backcolor=bufferBook.create_tag("backcolor",:background=>'yellow');
Tag_size_big=bufferBook.create_tag("sizebig",:size=>28);
Tag_size=bufferBook.create_tag("size",:size=>16);

textBook.set_buffer(bufferBook);
textBook.set_wrap_mode('word');
textBook.set_left_margin(20);
textBook.set_right_margin(20);
textBook.set_editable(false);
textBook.set_cursor_visible(false);

scrollwindowTextBook=Gtk::ScrolledWindow.new();
scrollwindowTextBook.set_min_content_height(ScreenY-550);#  1050=>600
scrollwindowTextBook.set_policy('automatic','automatic');
scrollwindowTextBook.add(textBook);
##~ $scro llwindowTextBook.set_max_content_width(600);




#OPen file fb2

   # when a row of the treeview is selected, it emits a signal
        # self.selection = view.get_selection()
        # self.selection.connect("changed", self.on_changed)

select1=list_of_books.selection
select1.signal_connect("changed"){|treeselection|



ReadInfoBook(root_dir+liststore.get_value(treeselection.selected,6),bufferBook,image,labelpage);
imageRate.set_from_file("Rate"+liststore.get_value(treeselection.selected,7).to_s+".png");
}	



# list_of_books.signal_connect('row-activated') { |treeview,sel_path,column|
# model = treeview.model
# path = sel_path
# iter = model.get_iter(path)
# ReadInfoBook(root_dir+iter[6],bufferBook,image,labelpage);
# imageRate.set_from_file("Rate"+iter[7].to_s+".png");
# }

ButtonRescan=Gtk::Button.new();
ButtonRescan.set_label('Rescan Library');
ButtonRescan.set_relief('none');
ButtonRescan.signal_connect('clicked') {add=0; onClickButtonRescan(window);} 
#,sub{$dbh.do("Delete from books");$liststore.clear();});

ButtonAdd=Gtk::Button.new();
ButtonAdd.set_label('Add new folder');
ButtonAdd.set_relief('none');
ButtonAdd.signal_connect('clicked') {add=1;onClickButtonRescan}

ButtonPrev=Gtk::Button.new();
ButtonPrev.set_label('Prev');
ButtonPrev.set_relief('none');
ButtonPrev.signal_connect('clicked') {
labeltext=labelpage.text
cur_page=labeltext[/((.)*) of /,1]
max_page=labeltext[/of ((.)*)/,1]
c=cur_page.to_i
m=max_page.to_i
if c>1 then c-=1 else c=m end
cur_page=c.to_s
labelpage.set_markup('<b>'+cur_page.to_s+'</b> of <b>'+max_page+'</b>');
treeselection=list_of_books.selection
if treeselection.selected[6]
ReadInfoBook(root_dir+liststore.get_value(treeselection.selected,6),bufferBook,image,labelpage,c);
end

};

ButtonNext=Gtk::Button.new();
ButtonNext.set_label('Next');
ButtonNext.set_relief('none');

ButtonNext.signal_connect('clicked') {
labeltext=labelpage.text
cur_page=labeltext[/((.)*) of /,1]
max_page=labeltext[/of ((.)*)/,1]
c=cur_page.to_i
m=max_page.to_i
if c<m then c+=1 else c=1 end
cur_page=c.to_s
labelpage.set_markup('<b>'+cur_page.to_s+'</b> of <b>'+max_page+'</b>');
treeselection=list_of_books.selection
if treeselection.selected[6]
ReadInfoBook(root_dir+liststore.get_value(treeselection.selected,6),bufferBook,image,labelpage,c);
end
}






##~ gtk.STATE_NORMAL
##~ State during normal operation.

##~ gtk.STATE_ACTIVE
##~ State of a currently active widget, such as a depressed button.

##~ gtk.STATE_PRELIGHT
##~ State indicating that the mouse pointer is over the widget and the widget will respond to mouse clicks.

##~ gtk.STATE_SELECTED
##~ State of a selected item, such the selected row in a list.

##~ gtk.STATE_INSENSITIVE
##~ State indicating that the widget is unresponsive to user actions.

#~ switch.modify_bg('normal',Gtk::Gdk::Color.new (:red=>0,:green=>0,:blue=>65535));
#~ switch.modify_fg('normal',Gtk::Gdk::Color.new ("red"=>65000,"green"=>65535,"blue"=>65535));
#~ color=Gtk::Gdk::color_parse('#742A2A');
               #$switch.modify_fg('prelight',$color);

               hboxbutton1=Gtk::Box.new('horizontal',20);
               hboxbutton1.pack_start(ButtonPrev,:expand=>true,:fill=>false,:panding=>30);
               hboxbutton1.pack_start(labelpage,:expand=>true,:fill=>false,:panding=>30);
               hboxbutton1.pack_start(ButtonNext,:expand=>true,:fill=>false,:panding=>30);
               hboxbutton1.set_homogeneous(true);

               hboxbuttonscan1=Gtk::Box.new('horizontal',20);
               hboxbuttonscan1.pack_start(ButtonRescan,:expand=>true,:fill=>false,:panding=>30);
               hboxbuttonscan1.pack_start(ButtonAdd,:expand=>true,:fill=>false,:panding=>30);
               hboxbuttonscan1.set_homogeneous(false);

               grid = Gtk::Grid.new();
               grid.row_spacing=20
               grid.column_spacing=20;
               grid.column_homogeneous=true;
               ##col,row,w,h
               ##0 row
               grid.attach(find,0,0,1,1);

               ##1 row
               grid.attach(scrollwindowTreeBook,0,1,2,1);
               ##2 row
               grid.attach(scrollwindowTextBook,0,2,1,1);
               grid.attach(event_box1,1,2,1,2);
               ##3 row
               grid.attach(event_box,0,3,1,1);

               ##4 row
               grid.attach(hboxbuttonscan1,0,4,1,1);
               grid.attach(hboxbutton1,1,4,1,1);


               window.add(grid)
               window.show_all
               ##ADD data DB from file

               updatelist(liststore,db,"")

               Gtk.main
