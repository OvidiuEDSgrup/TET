create proc  [dbo].[wValidareAngajamenteBugetare] (@parXML xml)
as begin
    Declare @indbug varchar(20),@eroare xml ,@indbug_cu_puncte varchar(30),@o_indbug varchar (20), 
	        @data_operarii datetime,@ora_operarii varchar(6),@o_data datetime,@new_indbug varchar(20),@new_suma_valuta float,@o_new_suma float,
	        @update bit,@numar varchar(8),@data datetime,@compartiment varchar(9),@beneficiar varchar(20),@suma float,@new_suma float,
	        @valuta char(3),@curs float,@explicatii varchar(200),@observatii varchar(200),@suma_valuta float,
	        @new_stare char(1),@o_stare char(1),@nr_cfp float,@nr_pozitie float,@nr_pozitieNC float,@comanda varchar(40),
	        @subtip varchar(2),@docXMLIaPozAngajamenteBugetare xml,@new_valuta char(3),@new_data datetime,@new_compartiment varchar(9),
	        @new_beneficiar varchar(20),@new_explicatii varchar(200),@new_observatii varchar(200),@new_curs float,@mesajeroare varchar(500)
	 select 
         @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
         @indbug= isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
         @subtip= isnull(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'),''),
         @numar= isnull(@parXML.value('(/row/@numar)[1]','varchar(8)'),''),
         @data= isnull(@parXML.value('(/row/@data)[1]','datetime'),'01-01-1901'),
         @compartiment= isnull(@parXML.value('(/row/@compartiment)[1]','varchar(9)'),''),
         @suma = isnull(@parXML.value('(/row/@suma)[1]','float'),0),
         @valuta = isnull(@parXML.value('(/row/@valuta)[1]','char(3)'),''),
         @curs = isnull(@parXML.value('(/row/@curs)[1]','float'),0),
         @beneficiar= isnull(@parXML.value('(/row/@beneficiar)[1]','varchar(20)'),''),
         @observatii= isnull(@parXML.value('(/row/@observatii)[1]','varchar(200)'),''),
         @explicatii=isnull( @parXML.value('(/row/@explicatii)[1]','varchar(200)'),''),
         
         @new_data= isnull(@parXML.value('(/row/row/@data)[1]','datetime'),'01-01-1901'),
         @new_indbug= isnull(@parXML.value('(/row/row/@indbug)[1]','varchar(20)'),''),
         @new_compartiment= isnull(@parXML.value('(/row/row/@compartiment)[1]','varchar(9)'),''),
         @new_suma=isnull(@parXML.value('(/row/row/@suma)[1]','float'),0),
         @new_valuta = isnull(@parXML.value('(/row/row/@valuta)[1]','char(3)'),''),
         @new_curs = isnull(@parXML.value('(/row/row/@curs)[1]','float'),0),
         @new_beneficiar= isnull(@parXML.value('(/row/row/@beneficiar)[1]','varchar(20)'),''),         
         @new_stare= isnull(@parXML.value('(/row/row/@stare)[1]','char(1)'),''),
         @new_explicatii=isnull( @parXML.value('(/row/row/@explicatii)[1]','varchar(200)'),''),
         @new_observatii= isnull(@parXML.value('(/row/row/@observatii)[1]','varchar(200)'),''),
         
         @o_stare= isnull(@parXML.value('(/row/@stare)[1]','char(1)'),''),
         @o_new_suma=isnull(@parXML.value('(/row/row/@o_suma)[1]','float'),0),
         @o_indbug= isnull(@parXML.value('(/row/row/@o_indbug)[1]','varchar(20)'),'')
	
	
   if @subtip='AN' and @update=0 and @numar<>'' 
      begin
      set @mesajeroare='Pentru adaugarea unui angajament bugetar nou, trebuie sa reveniti in fereantra "Propuneri/Ang.bug." si sa accesati butonul de adaugare de acolo!!'
       raiserror(@mesajeroare,11,1)
       return -1
      end             
  
   if @subtip='AN' and @update=0 and @indbug=''
      begin
      set @mesajeroare='Introduceti indicatorul bugetar pentru acest angajament!!'
       raiserror(@mesajeroare,11,1)
       return -1
      end  
   
   if @subtip='AN' and @update=0 and not exists (select indbug from indbug where indbug=@indbug )
      begin
      set @mesajeroare='Indicatorul introdus nu exista in baza de date!!'
       raiserror(@mesajeroare,11,1)
       return -1
      end      
      
   if @subtip='AN' and @update=0 and @compartiment<>'' and not exists (select cod from lm where cod=@compartiment )
      begin
      set @mesajeroare='Compartimentul introdus nu exista in baza de date!!'
       raiserror(@mesajeroare,11,1)
       return -1
      end  
      
   if @subtip='AN' and @update=0 and @beneficiar<>'' and not exists (select cod from lm where cod=@beneficiar )
      begin
      set @mesajeroare='Beneficiarul introdus nu exista in baza de date!!'
       raiserror(@mesajeroare,11,1)
       return -1
      end  
         
    if @subtip='AN' and @update=0 and @suma=0
      begin
      set @mesajeroare='Suma nu poate fi 0!!'
       raiserror(@mesajeroare,11,1)
       return -1
      end                 
       
   return 0
end
