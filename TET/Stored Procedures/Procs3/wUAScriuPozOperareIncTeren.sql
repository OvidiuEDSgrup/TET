/****** Object:  StoredProcedure [dbo].[wUAScriuPozOperareIncTeren]    Script Date: 01/05/2011 23:20:13 ******/
--***
/* descriere... */
create procedure  [dbo].[wUAScriuPozOperareIncTeren](@sesiune varchar(50), @parXML xml) 
as     
begin
declare @abonat varchar(13), @localitate varchar(50),@factura_fact varchar(13),@penalizari_fact float,@tip_inc varchar(3),@data_inc datetime,
        @sold_fact float,@loc_de_munca_fact varchar(13),@cont varchar(8),@utilizator varchar(8),@abonat_fact varchar(13),@docXML xml,@contract_fact varchar(13),
        @casier_inc varchar(13),@suma_inc float,@data_fact datetime, @nr_doc_inc int,@id_fact int,@mesaj varchar(200),@nrchit char(8),@nrtemp int, @inXML varchar(1),
        @nr_fact_avans varchar(13),@id_fact_avans int,@suma_incasata_total float,@doc int,@new_doc int,@nr_incasare_c varchar(8),@explicatii varchar(200),
        @userAsis varchar(10),@lm varchar(13)
begin try

select	@abonat = isnull(@parXML.value('(/row/row/@abonat)[1]','varchar(13)'),''),	
		@explicatii = isnull(@parXML.value('(/row/row/@explicatii)[1]','varchar(200)'),''),	
		@suma_inc = isnull(@parXML.value('(/row/row/@suma)[1]','float'),0),
		@new_doc = isnull(@parXML.value('(/row/row/@document)[1]','int'),0),
        
        @data_inc=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01-01-1901'),
        @casier_inc = isnull(@parXML.value('(/row/@casier)[1]','varchar(13)'),''),
        @tip_inc = isnull(@parXML.value('(/row/@tip_inc)[1]','varchar(3)'),''),
		@doc = isnull(@parXML.value('(/row/@doc_next)[1]','varchar(8)'),''),
		@nr_incasare_c = isnull(@parXML.value('(/row/@nr_incasare_c)[1]','varchar(8)'),'')      
    	
	
	if @nr_incasare_c='' and @doc=''
	begin
	   set @mesaj='Intorduceti numarul chitantei!!'
	   raiserror(@mesaj,11,1)
	end
	--sp_help incasarifactabon
	if @nr_incasare_c='' and (@casier_inc='' or (not exists (select cod_casier from Casieri where Cod_casier=@casier_inc))) 
	begin
	   set @mesaj='Casierul nu a fost introdus corect!!'
	   raiserror(@mesaj,11,1)
	end
	
	if @nr_incasare_c='' and (@tip_inc=''or (not exists (select id from Tipuri_de_incasare where ID=@tip_inc)))
	begin
	   set @mesaj='Intorduceti tipul de incasare!!'
	   raiserror(@mesaj,11,1)
	end	
	
	if @suma_inc<=0 or isnumeric(@suma_inc)<>1
		begin
			set @mesaj='Suma nu a fost introdussa corect!!'
			Raiserror(@mesaj,11,1)
		end	  
		
	if @abonat='' or not exists (select abonat from Abonati where abonat=@abonat)
		begin
			set @mesaj='Abonatul introdus nu este in baza de date!'
			raiserror(@mesaj,11,1)
		end 
		
	---------
	set @Utilizator=dbo.iauUtilizatorCurent()  
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

	declare @lista_lm int
	set @lm=(select Loc_de_munca from abonati where abonat=@abonat )
	set @lista_lm=(case when exists (select 1 from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

	---------
		
	if (@lista_lm=1 and not exists (select cod from LMFiltrare where Cod=@lm and utilizator=@utilizator))
		begin     
			set @mesaj='Nu aveti drept de operare pentru acest loc de munca!!'  
			raiserror(@mesaj,11,1)  
		end			
	
	if @nr_incasare_c='' and @doc<>''
	   if exists (select document from IncasariFactAbon where Document=@doc and Abonat=@abonat and Data=@data_inc )
			begin
			set @mesaj='Numarul de chitanta introdus exista deja in baza de date!!'
			raiserror(@mesaj,11,1)
			end
	   else
			begin 
				update Casieri set Terminal=@casier_inc where Cod_casier=@utilizator
				update Casieri set Nr_incasare=@doc where Cod_casier=@utilizator 
		                                       or Cod_casier=(select Terminal from Casieri where Cod_casier=@utilizator )
				update casieri set data=@data_inc, tip_incasare=@tip_inc,Suma=0 where Cod_casier=@utilizator 
				set @nr_doc_inc=@doc	
					
			end
	
	if @nr_incasare_c<>'' and @doc<>''
	    if exists (select document from IncasariFactAbon where Document=@doc and Abonat=@abonat and Data=@data_inc )
			begin
			set @mesaj='Numarul de chitanta introdus exista deja in baza de date!!'
			raiserror(@mesaj,11,1)
			end
		else	
			begin
				set @nr_doc_inc=@doc
			end
	
	if @new_doc<>''
		if exists (select document from IncasariFactAbon where Document=@new_doc and Abonat=@abonat and Data=@data_inc )
			begin
			set @mesaj='Numarul de chitanta introdus exista deja in baza de date!!'
			raiserror(@mesaj,11,1)
			end
		else		
		begin
			set @nr_doc_inc=@new_doc
			update Casieri set Nr_incasare=@doc where Cod_casier=@utilizator 
	                                           or Cod_casier=(select Terminal from Casieri where Cod_casier=@utilizator )	
		end   
	
	set @cont=ISNULL((select RTRIM(cont_specific) from tipuri_de_incasare where ID=@tip_inc),'')
 
   set @suma_incasata_total=@suma_inc
   declare facturi_cu_sold cursor                      
   for select distinct id_factura,sold,abonat,contract,penalizari,loc_de_munca ,data
   from factAbon          
   where abonat=@abonat  and sold>0.001 and data<=@data_inc  and tip not in ('AV','AP')
   order by data  
   open facturi_cu_sold                     
   fetch next from facturi_cu_sold 
              into @id_fact,@sold_fact,@abonat_fact,@contract_fact,@penalizari_fact,@loc_de_munca_fact,@data_fact           
  
    while  @@fetch_status = 0   and @suma_inc>0.001  
    begin      		
    
    if @suma_inc>=@sold_fact
		begin

		exec UAScriuIncasare 'IF',@tip_inc,@nr_doc_inc output,@data_inc,@abonat,@loc_de_munca_fact,@id_fact,@sold_fact,0,0,@casier_inc,0,@utilizator,1,@explicatii
		set @suma_inc=@suma_inc-@sold_fact
		end
	else
		if @suma_inc<@sold_fact and @suma_inc>0
			begin
				exec UAScriuIncasare 'IF',@tip_inc,@nr_doc_inc output,@data_inc,@abonat,@loc_de_munca_fact,@id_fact,@suma_inc,0,0,@casier_inc,0,@utilizator,1,@explicatii
				set @suma_inc=0
			end 
	 
	 fetch next from facturi_cu_sold 
              into @id_fact,@sold_fact,@abonat_fact,@contract_fact,@penalizari_fact,@loc_de_munca_fact ,@data_fact                     
    end                     
    close facturi_cu_sold                   
    deallocate facturi_cu_sold
    
    if @suma_inc>0.001
    begin         	
    	exec UAScriuAvans @abonat,@suma_inc,@data_inc,0,@utilizator,@casier_inc,@lm,@tip_inc,'AV',@nr_doc_inc output,@nr_fact_avans output,@id_fact_avans output,1
    end
    
    declare @denabonat varchar(50)
    set @denabonat = rtrim((select denumire from abonati where abonat=@abonat))
    
    if ISNUMERIC(@nr_doc_inc)=1 
		begin
			--select 'S-a incasat suma '+rtrim(@suma_incasata_total)+'RON, pe chitanta cu numarul '+rtrim(@nr_doc_inc)+' !' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
			select 'S-a incasat suma '+rtrim(@suma_incasata_total)+'RON, pe chitanta cu numarul '+rtrim(@nr_doc_inc)+' pe abonatul '+rtrim(@denabonat)+' !' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
			
			set @nr_doc_inc=convert(int,@nr_doc_inc)+1
			update Casieri set Nr_incasare=@nr_doc_inc where Cod_casier=@utilizator 
	                                           or Cod_casier=(select Terminal from Casieri where Cod_casier=@utilizator )
	        update Casieri set Suma=suma+@suma_incasata_total where  Cod_casier=@utilizator                                   
		
		end
		else 
		begin
			set @mesaj='Numarul de chitanta nu este numeric!'
			raiserror(@mesaj,11,1)
		end		

	  	
	  	set @docXML='<row casier="' + rtrim(@casier_inc)+ '" data="' + convert(char(10), @data_inc, 101)+ '" tip_inc="' + rtrim(@tip_inc)+'"/>'
		exec wUAIaPozOperareIncTeren @sesiune=@sesiune, @parXML=@docXML
	 	 
end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
--select * from IncasariFactAbon
