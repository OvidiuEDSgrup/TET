create procedure  [dbo].[wScriuPozAngajamenteBugetare] @sesiune varchar(50), @parXML xml  
as
begin try 
begin transaction tran2
	declare	@mesajeroare varchar(300), @userASiS varchar(20),@sub char(9),@tip char(2)
	
	DECLARE @indbug varchar(20),@eroare xml ,@indbug_cu_puncte varchar(30),@o_indbug varchar (20), 
        @data_operarii datetime,@ora_operarii varchar(6),@o_data datetime,@new_indbug varchar(20),@new_suma_valuta float,@o_new_suma float,
        @update bit,@numar varchar(8),@data datetime,@compartiment varchar(9),@beneficiar varchar(20),@suma float,@new_suma float,
        @valuta char(3),@curs float,@explicatii varchar(200),@observatii varchar(200),@suma_valuta float,
        @new_stare char(1),@o_stare char(1),@nr_cfp float,@nr_pozitie float,@nr_pozitieNC float,@comanda varchar(40),
        @subtip varchar(2),@docXMLIaPozAngajamenteBugetare xml,@new_valuta char(3),@new_data datetime,@new_compartiment varchar(9),
        @new_beneficiar varchar(20),@new_explicatii varchar(200),@new_observatii varchar(200),@new_curs float,@new_datam datetime
    --citire date din xml
   
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
         @new_datam=isnull(@parXML.value('(/row/row/@datam)[1]','datetime'),'01-01-1901'),
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
         
	exec wValidareAngajamenteBugetare  @parXML

	declare @utilizator varchar(50),@lista_lm int
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	if @utilizator is null
		return -1

	select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else 0 end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA'
	set @lista_lm=ISNULL(@lista_lm,0)
	
	--**************Start adaugare angajament bugetar********************** 
	if @subtip='AN'--se adauga un angajament bugetar nou
	begin
			
		--identificare suma disponibila pe indicator bugetar
		declare @suma_disponibila float,@suma_disponibila_total float
		set @suma=convert(decimal(12,3),@suma)
				
		if @suma<0.001--daca se introduce ang bugetar cu suma negativa se face verificare ca suma angajata sa nu devina mai mica decat suma ordonantata
			begin
				set @suma_disponibila_total=isnull((select sum(suma) from angbug where Loc_de_munca=@compartiment and indicator=@indbug),0)-
										isnull((select sum(suma) from ordonantari where rtrim(Compartiment) like rtrim(@compartiment)+'%' and indicator=@indbug),0)
				
				if @suma_disponibila_total+@suma<0
					begin
						set @mesajeroare='Nu poate fi angajata o suma mai mica de '+convert(varchar,convert(decimal(12,3),@suma_disponibila_total*(-1)))+
										 ' intrucat suma ordonantata ar deveni mai mare decat suma angajamentelor bugetare de pe acest indicator si loc de munca!!'
						raiserror(@mesajeroare,11,1)
					end
			end

	
		set @suma_disponibila=--planul bugetar+rectificari bugetare-angajamente bugetare realizate pe indicator si care au cel putin viza de propunere		
			(isnull(convert(decimal(12,3),(select sum(p.suma) from pozncon p left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_munca=lu.cod
																where substring(p.comanda,21,20)=@indbug
																	and p.tip='AO' 
																	and (p.Loc_munca=@compartiment or ISNULL(@compartiment,'')='')
																	and substring(p.numar,1,7)in ('BA_TRIM')
																	and datepart(quarter,p.data)<=datepart(quarter,@data)
																	and year(p.data)=year(@data) and (@lista_lm=0 or lu.cod is not null))),0)+
																	
							 isnull(convert(decimal(12,3),(select sum(p.suma) from pozncon p left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_munca=lu.cod
																 where substring(p.comanda,21,20)=@indbug 
																	and p.tip='AO' 
																	and (p.Loc_munca=@compartiment or ISNULL(@compartiment,'')='')
																	and substring(p.numar,1,7)in ('RB_TRIM')
																	and datepart(quarter,p.data)<=datepart(quarter,@data)
																	and year(p.data)=year(@data) and (@lista_lm=0 or lu.cod is not null))),0)-                                                                                    
		                                                                                                 
							isnull(convert(decimal(12,3),(select sum(suma) from angbug left outer join LMFiltrare lu on lu.utilizator=@utilizator and angbug.Loc_de_munca=lu.cod
																where indicator=@indbug 
																	and stare>'0'
																	and stare<>'4'
																	and (Loc_de_munca=@compartiment or ISNULL(@compartiment,'')='')
																	and datepart(quarter,data)<=datepart(quarter,@data) 
																	and year(data)=year(@data) and (@lista_lm=0 or lu.cod is not null))),0))														   
	
			if  @suma_disponibila<@suma --or 1=1--daca suma disponibila este mai mica decat suma introdusa=>eroare
				begin
					set @mesajeroare='Suma introdusa ('+convert(varchar,(convert(decimal(12,3),@suma)))+
							 ') este mai mare decat suma disponibila ('+convert(varchar,convert(decimal(12,3),@suma_disponibila))+
							 ') pe acest indicator bugetar!!'
					raiserror(@mesajeroare, 11, 1)
				end

			declare @UltNrABug char(8)		
			exec luare_date_par 'GE', 'ULTNRABUG', '', @UltNrABug output, 0
			set  @UltNrABug= @UltNrABug+1
			 
			while exists (select 1 from angbug where Numar=@UltNrABug and year(Data_angajament)=YEAR(@data))
				set @UltNrABug=@UltNrABug+1
			 
			exec setare_par 'GE', 'ULTNRABUG', null, null, @UltNrABug, null
			set @numar=@UltNrABug
			
			set @new_suma_valuta=(case when @new_curs<>0 and @new_valuta<>'' then @suma/@new_curs else 0 end) 

			insert into angbug(indicator,numar,data,stare,loc_de_munca,beneficiar,suma,valuta,curs,suma_valuta,explicatii,
				observatii,utilizator,data_operarii,ora_operarii,data_angajament) 
			select @indbug,@numar,@data,convert(varchar,'0'),@compartiment,@beneficiar,@suma,@valuta,@curs,@new_suma_valuta,
				@explicatii,@observatii,@utilizator,convert(datetime, convert(char(10), getdate(), 101), 101),
				RTrim(replace(convert(char(8), getdate(), 108), ':', '')) ,'1901-01-01 00:00:00.000'				
		/*if  @suma_disponibila<@suma
			select 'Suma introdusa ('+convert(varchar,(convert(decimal(12,3),@suma)))+
							 ') este mai mare decat suma disponibila ('+convert(varchar,@suma_disponibila)+
							 ') pe acest indicator bugetar!' as textMesaj, 'Avertizare' as titluMesaj for xml raw, root('Mesaje')*/
	commit transaction tran2 	
	end
	--**************Stop adaugare angajament bugetar********************** 

declare @docXMLIaPozAngBug xml
if @subtip='AN' 
	set @docXMLIaPozAngBug = '<row indbug="' + rtrim(@indbug) + '" numar="' + rtrim(@numar)+'" data="' + convert(char(10), @data, 101) +'"/>'
end try
begin catch
	rollback transaction tran2
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
