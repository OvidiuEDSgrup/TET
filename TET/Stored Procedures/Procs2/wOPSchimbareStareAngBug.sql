create procedure [dbo].[wOPSchimbareStareAngBug] @sesiune varchar(50), @parXML xml  
as
begin
declare	@mesajeroare varchar(300),@utilizator char(10), @userASiS varchar(20),@sub char(9),@tip char(2)
	
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
if @utilizator is null
	return -1

DECLARE @indbug varchar(20),@eroare xml ,@indbug_cu_puncte varchar(30),
        @data_operarii datetime,@ora_operarii varchar(6),
        @update bit,@numar varchar(8),@data datetime,@datam datetime,@compartiment varchar(9),@beneficiar varchar(20),@suma float,--@new_suma float,
        @valuta char(3),@curs float,@explicatii varchar(200),@observatii varchar(200),@suma_valuta float,
        @stare char(1), @o_stare char(1),
        @nr_cfp float,@nr_pozitie float,@nr_pozitieNC float,@comanda varchar(40),
        @subtip varchar(2)
    --citire date din xml
begin try    
    select 
         @update = isnull(@parXML.value('(parametri/row/@update)[1]','bit'),0),
         @indbug= isnull(@parXML.value('(parametri/@indbug)[1]','varchar(20)'),''),
         @subtip= isnull(@parXML.value('(parametri/row/@subtip)[1]','varchar(2)'),''),
         @numar= isnull(@parXML.value('(parametri/@numar)[1]','varchar(8)'),''),
         @data= isnull(@parXML.value('(parametri/@data)[1]','datetime'),'01-01-1901'),
         @datam= isnull(@parXML.value('(parametri/@datam)[1]','datetime'),@data),
         @compartiment= isnull(@parXML.value('(parametri/@compartiment)[1]','varchar(9)'),''),
         @suma = isnull(@parXML.value('(parametri/@suma)[1]','float'),0),
         @valuta = isnull(@parXML.value('(parametri/@valuta)[1]','char(3)'),''),
         @curs = isnull(@parXML.value('(parametri/@curs)[1]','float'),0),
         @beneficiar= isnull(@parXML.value('(parametri/@beneficiar)[1]','varchar(20)'),''),  
         @stare= isnull(@parXML.value('(parametri/@stare)[1]','char(1)'),''),
         @observatii= isnull(@parXML.value('(parametri/@observatii)[1]','varchar(200)'),''),
         @explicatii=isnull( @parXML.value('(parametri/@explicatii)[1]','varchar(200)'),'')
	 
	 set @o_stare=(select stare from angbug where numar = @numar and indicator=@indbug and data=@data)         
    
       ---***********Start Modificare stare angajament bugetar*********************
	
	if (NOT (@o_stare='0' AND (@stare='1' OR @stare='4') OR @o_stare='1' AND @stare='5' OR @o_stare='5' 
		AND @stare='6') AND @stare<>@o_stare )
		begin
			set @mesajeroare='Nu este permisa trecerea in acasta stare a angajamentului bugetar!' 
			raiserror(@mesajeroare,11,1)		
		end 	  
  
    --in cazul in care angajamentul bugetar va fi modificat in starea 1(viza prop),se va adauga o pozitie corspunzatoare in tabelul registrucfp
	if @stare='1' and @o_stare<>@stare
		begin   
			if @datam<@data
				raiserror('Data CFP trebuie sa fie o data ulterioara datei angajamentului bugetar!',11,1)
   
	declare @suma_disponibila float
	set @suma=convert(decimal(12,3),@suma)
	set @suma_disponibila=
       isnull(convert(decimal(12,3),(select sum(p.suma) from pozncon p where substring(p.comanda,21,20)=@indbug 
                                                                         and p.tip='AO' 
                                                                         and substring(p.numar,1,7)in ('BA_TRIM')
																		 and datepart(quarter,p.data)<=datepart(quarter,@data) 
																		 and year(p.data)=year(@data))),0)+
	   isnull(convert(decimal(12,3),(select sum(p.suma) from pozncon p where substring(p.comanda,21,20)=@indbug 
                                                                         and p.tip='AO' 
                                                                         and substring(p.numar,1,7)in ('RB_TRIM')
                                                                         and p.data<=@data
                                                                         and year(p.data)=year(@data))),0)-   																  
	   isnull(convert(decimal(12,3),(select sum(suma)from angbug where indicator=@indbug 
																   and stare>'0'
                                                                   and stare<>'4'
																   and datepart(quarter,data)<=datepart(quarter,@data) 
																   and year(data)=year(@data))),0)
   	if @suma_disponibila<@suma
 		begin
			set @mesajeroare='Acest angajament bugetar nu mai poate primi viza CFP, intrucat suma lui ('+convert(varchar,(convert(decimal(12,3),@suma)))+
							 ') este mai mare decat suma disponibila ('+convert(varchar,@suma_disponibila)+
							 ') pe acest indicator bugetar!!'
			raiserror(@mesajeroare, 11, 1)
        end
   
     exec luare_date_par 'GE', 'ULTNROPB', 0, @nr_cfp output, ''
	 set @nr_cfp=@nr_cfp+1
	 exec setare_par 'GE', 'ULTNROPB', null, null, @nr_cfp, null 
	 
     set @nr_pozitie=isnull((select top 1 numar_pozitie from registrucfp 
	              where indicator=@indbug and numar=@numar and data=@data and tip='P'
	              order by numar_pozitie desc),0)+1
	      
	 insert into registrucfp (tip,indicator,numar,data,numar_pozitie,numar_cfp,data_cfp,observatii,utilizator,data_operarii,ora_operarii)
	             select 'P',@indbug,@numar,@data,@nr_pozitie,@nr_cfp,convert(char(10),@datam,101),'Viza propunere',@utilizator,
	             convert(datetime, convert(char(10), getdate(), 101), 101),RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
   end
 
 --in cazul in care angajamentul bugetar va fi modificat in starea 4(respins),se va adauga o pozitie corspunzatoare in tabelul registrucfp
  if @stare='4'and @o_stare<>@stare
     begin
		if @datam<@data
			begin
				set @mesajeroare='Data CFP trebuie sa fie o data ulterioara datei angajamentului bugetar!!'
				raiserror(@mesajeroare,11,1)
			end   
		exec luare_date_par 'GE', 'ULTNROPB', 0, @nr_cfp output, ''
		set @nr_cfp=@nr_cfp+1
		exec setare_par 'GE', 'ULTNROPB', null, null, @nr_cfp, null 
	 
		set @nr_pozitie=isnull((select top 1 numar_pozitie from registrucfp 
								where indicator=@indbug and numar=@numar and data=@data and tip='R'
								order by numar_pozitie desc),0)+1 
	              
		insert into registrucfp (tip,indicator,numar,data,numar_pozitie,numar_cfp,data_cfp,observatii,utilizator,data_operarii,ora_operarii)
	    select 'R',@indbug,@numar,@data,@nr_pozitie,@nr_cfp,convert(char(10),@datam,101),'Respingere propunere',@utilizator,
	            convert(datetime, convert(char(10), getdate(), 101), 101),RTrim(replace(convert(char(8), getdate(), 108), ':', ''))             
    end  
 
    --in cazul in care angajamentul bugetar va fi modificat in starea 6(viza angajare bugetara),se va adauga o pozitie corspunzatoare in tabelul registrucfp.
    --deasemenea se va aduga si nota contabila corespunzatoare in tabelul pozncon
	if @stare='6'and @o_stare<>@stare
		begin
			if @datam<@data
				begin
					set @mesajeroare='Data CFP trebuie sa fie o data ulterioara datei angajamentului bugetar!!'
					raiserror(@mesajeroare,11,1)
				end   
			exec luare_date_par 'GE', 'ULTNROPB', 0, @nr_cfp output, ''
			set @nr_cfp=@nr_cfp+1
			exec setare_par 'GE', 'ULTNROPB', null, null, @nr_cfp, null 
	 
			set @nr_pozitie=isnull((select top 1 numar_pozitie from registrucfp 
									where indicator=@indbug and numar=@numar and data=@data and tip='B'
									order by numar_pozitie desc),0)+1 
	              
			insert into registrucfp (tip,indicator,numar,data,numar_pozitie,numar_cfp,data_cfp,observatii,utilizator,data_operarii,ora_operarii)
	        select 'B',@indbug,@numar,@data,@nr_pozitie,@nr_cfp,convert(char(10),@datam,101),'Viza angajare bugetara',@utilizator,
	             convert(datetime, convert(char(10), getdate(), 101), 101),RTrim(replace(convert(char(8), getdate(), 108), ':', ''))             
    
			----Adaugare pozitie note contabile
			exec luare_date_par 'DO', 'POZITIE', 0, @nr_pozitieNC output, ''
			set @nr_pozitieNC=@nr_pozitieNC+1
			exec setare_par 'DO', 'POZITIE', null, null, @nr_pozitieNC, null 
			set @comanda='                    '+ltrim(rtrim(@indbug)) 
			set @suma_valuta=(case when @curs<>0 and @valuta<>'' then @suma/@curs else 0 end)   
			
			insert into pozncon (subunitate,tip,numar,data,cont_debitor,cont_creditor,suma,valuta,curs,suma_valuta,explicatii,utilizator,data_operarii,
								ora_operarii,nr_pozitie,loc_munca,comanda,tert,jurnal)
            select '1','AO',@numar,getdate(),'8066','',@suma,@valuta,@curs,@suma_valuta,'Angajare bugetara '+convert(varchar,@nr_cfp),@utilizator,
                 convert(datetime, convert(char(10), getdate(), 101), 101),RTrim(replace(convert(char(8), getdate(), 108), ':', '')),          
                 @nr_pozitieNC,@beneficiar,@comanda,'',''
		end  
   
	if @stare<>@o_stare
		--modificare stare angajament bugetar
		update angbug set stare=@stare where numar = @numar and indicator=@indbug and data=@data 
  
end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
	
end
