create proc [dbo].[wValidareAngajamenteLegale] (@parXML xml)
as begin
    Declare @update bit,@numar_ordonantare varchar(8),@data_ordonantare datetime,@numar_ang_bug varchar(8),
	        @data_ang_bug datetime,@numar_ang_legal varchar(8),@data_ang_legal datetime,@contract varchar(20),
	        @mod_de_plata varchar(30),@documente_justificative varchar (200),@new_contract varchar(20),@o_data_OP datetime,
	        @o_new_numar_ang_bug varchar(8),@new_data_ordonantare datetime,@new_data_CFP datetime,
	        @new_numar_ang_bug varchar(8),@new_mod_de_plata varchar(30),@new_numar varchar(8),@data_OP datetime,
	        @o_numar varchar(8),@new_numar_ang_legal varchar(8), @new_numar_ordonantare varchar(8),@o_data_ordonantare datetime,
	        @compartiment varchar(9),@beneficiar varchar(20),@suma float,@new_suma float,@o_new_suma float,
	        @valuta char(3),@curs float,@explicatii varchar(200),@observatii varchar(200),@suma_valuta float,
	        @stare char(10),@o_stare char(10),@nr_cfp float,@nr_pozitie int,@nr_pozitieNC int,@comanda varchar(40),@new_data_OP datetime,
	        @subtip varchar(2),@docXMLIaPozAngajamenteBugetare xml,@new_valuta char(3),@new_data datetime,@new_compartiment varchar(9),
	        @new_beneficiar varchar(20),@new_explicatii varchar(200),@new_observatii varchar(200),@new_curs float,@new_suma_valuta float,
	        @new_documente_justificative varchar(200),@indbug varchar(20),@indbug_ang_bug varchar(20),@eroare xml ,@indbug_cu_puncte varchar(30),@o_indbug varchar (20), 
	        @data_operarii datetime,@ora_operarii varchar(6),@o_data datetime,@mesajeroare varchar(500),@numar_ang_bug_AC varchar(30),@data_angbug_AC datetime
	 select 
         @indbug= isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
         @numar_ordonantare= isnull(@parXML.value('(/row/@numar_ordonantare)[1]','varchar(8)'),''),
         @numar_ang_bug_AC= isnull(@parXML.value('(/row/@numar_ang_bug_AC)[1]','varchar(30)'),''),
         @data_ordonantare= @parXML.value('(/row/@data_ordonantare)[1]','datetime'),
         @data_ang_bug= @parXML.value('(/row/@data_ang_bug)[1]','datetime'),
         @numar_ang_legal= isnull(@parXML.value('(/row/@numar_ang_legal)[1]','varchar(8)'),''),
         @data_ang_legal= @parXML.value('(/row/@data_ang_legal)[1]','datetime'),
         @beneficiar= isnull(@parXML.value('(/row/@beneficiar)[1]','varchar(20)'),''),
         @contract=isnull(@parXML.value('(/row/@contract)[1]','varchar(20)'),''),
         @compartiment= isnull(@parXML.value('(/row/@compartiment)[1]','varchar(9)'),''),
         @suma = isnull(@parXML.value('(/row/@suma)[1]','float'),0),
         @valuta = isnull(@parXML.value('(/row/@valuta)[1]','char(3)'),''),
         @curs = isnull(@parXML.value('(/row/@curs)[1]','float'),0),         
         @mod_de_plata=isnull(@parXML.value('(/row/@mod_de_plata)[1]','varchar(30)'),''),
         @documente_justificative=isnull(@parXML.value('(/row/@documente_justificative)[1]','varchar(200)'),''),
         @observatii= isnull(@parXML.value('(/row/@observatii)[1]','varchar(200)'),''),
         @explicatii=isnull( @parXML.value('(/row/@explicatii)[1]','varchar(200)'),''),
         @stare= isnull(@parXML.value('(/row/@stare)[1]','char(10)'),''),
         
         @update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
         @subtip= isnull(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'),''),
         @nr_pozitie = isnull(@parXML.value('(/row/row/@nr_pozitie)[1]','int'),0),
         @data_OP = @parXML.value('(/row/row/@data_OP)[1]','datetime'),
         
         @new_numar_ang_legal= isnull(@parXML.value('(/row/row/@numar_ang_legal)[1]','varchar(8)'),''),
         @new_contract=isnull(@parXML.value('(/row/row/@contract)[1]','varchar(20)'),''),
         @new_numar_ang_bug= isnull(@parXML.value('(/row/row/@numar_ang_bug)[1]','varchar(8)'),''),
         @new_numar= isnull(@parXML.value('(/row/row/@numar)[1]','varchar(8)'),''),
         @new_numar_ordonantare= isnull(@parXML.value('(/row/row/@numar_ordonantare)[1]','varchar(8)'),''),
         @new_mod_de_plata=isnull(@parXML.value('(/row/row/@mod_de_plata)[1]','varchar(30)'),''),
         @new_documente_justificative=isnull(@parXML.value('(/row/row/@documente_justificative)[1]','varchar(200)'),''),
         @new_data= @parXML.value('(/row/row/@data)[1]','datetime'), 
         @new_data_OP= @parXML.value('(/row/row/@data_OP)[1]','datetime'),   
         @new_data_CFP= isnull(@parXML.value('(/row/row/@data_CFP)[1]','datetime'),'01-01-1901'),     
         @new_data_ordonantare= @parXML.value('(/row/row/@data_ordonantare)[1]','datetime'),       
         @new_compartiment= isnull(@parXML.value('(/row/row/@compartiment)[1]','varchar(9)'),''),
         @new_suma=isnull(@parXML.value('(/row/row/@suma)[1]','float'),0),
         @new_valuta = isnull(@parXML.value('(/row/row/@valuta)[1]','char(3)'),''),
         @new_curs = isnull(@parXML.value('(/row/row/@curs)[1]','float'),0),
         @new_beneficiar= isnull(@parXML.value('(/row/row/@beneficiar)[1]','varchar(20)'),''),
         @new_explicatii=isnull( @parXML.value('(/row/row/@explicatii)[1]','varchar(200)'),''),         
         @new_observatii= isnull(@parXML.value('(/row/row/@observatii)[1]','varchar(200)'),''),
         @new_contract=isnull(@parXML.value('(/row/row/@contract)[1]','varchar(20)'),''),
        
         @o_stare= isnull(@parXML.value('(/row/@stare)[1]','char(10)'),''),
         @o_numar= isnull(@parXML.value('(/row/row/@o_numar)[1]','varchar(8)'),''),
         @o_new_suma=isnull(@parXML.value('(/row/row/@o_suma)[1]','float'),0),
         @o_new_numar_ang_bug= isnull(@parXML.value('(/row/row/@o_numar_ang_bug)[1]','varchar(8)'),''),
         @o_data_OP = @parXML.value('(/row/row/@o_data_OP)[1]','datetime'),
         @o_data_ordonantare= @parXML.value('(/row/row/@o_data_ordonantare)[1]','datetime')
	
	if  @subtip='AO'
     	begin
			set @numar_ang_bug=(select substring(@numar_ang_bug_AC,1,CHARINDEX('|',@numar_ang_bug_AC,1)-1))
			set @data_angbug_AC=(select substring(@numar_ang_bug_AC,CHARINDEX('|',@numar_ang_bug_AC,1)+1,LEN(@numar_ang_bug_AC)))
		end
   
	if @subtip='MA' and @update=0 
		begin
			set @mesajeroare='Pentru modificarea datelor angajamenutului legal, selectati pozitia "Vizualizare/Modificare date ang.leg." si accesati butonul de modificare!!'
			raiserror(@mesajeroare,11,1)
			return -1
		end       
      
	if @subtip='AO' and @update=0 and @numar_ordonantare<>'' 
		begin
			set @mesajeroare='Pentru adaugarea unui angajament legal nou trebuie sa reveniti in fereantra "Ang.leg./Ordonantari" si sa accesati butonul de adaugare de acolo!!'
			raiserror(@mesajeroare,11,1)
			return -1
		end  
      
   if @subtip='VO'
	begin 
		if @update=1 
			begin
				set @mesajeroare='Nu se pot face modificari pe vizele cfp!!'
				raiserror(@mesajeroare,11,1)
				return -1
			end
			
		if exists (select numar_cfp from registrucfp where numar=@numar_ordonantare and tip='O')
			begin
				set @mesajeroare='Pentru aceasta ordonantare exista deja viza CFP!'
				raiserror(@mesajeroare, 11, 1)
				return -1
			end	
	end		
      
	if @subtip='AO' and @update=0 and not exists (select 1 from angbug where numar=@numar_ang_bug)
		begin
			set @mesajeroare='Angajamentul bugetar introdus nu exista in baza de date!!'
			raiserror(@mesajeroare,11,1)
			return -1
		end           
    
	if @subtip='AO'
		begin      
			if @new_contract<>'' and not exists (select 1 from terti where tert=@new_contract)
				begin
					set @mesajeroare='Furnizorul introdus nu exista in baza de date!!'
					raiserror(@mesajeroare,11,1)
					return -1
				end     
      
			if @suma=0 
				begin
					set @mesajeroare='Suma angajamentului legal nu poate fi 0!!'
					raiserror(@mesajeroare,11,1)
					return -1
				end   
		end          
    return 0
end
