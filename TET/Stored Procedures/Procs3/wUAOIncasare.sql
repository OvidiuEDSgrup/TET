/****** Object:  StoredProcedure [dbo].[wUAOIncasare]    Script Date: 01/05/2011 23:20:13 ******/
--***
/* descriere... */
create procedure  [dbo].[wUAOIncasare] (@sesiune varchar(50), @parXML xml) 
as     
begin
declare @abonat varchar(13), @localitate varchar(50),@factura_fact varchar(13),@penalizari_fact float,@tip_inc varchar(2),@data_inc datetime,
        @sold_fact float,@loc_de_munca_fact varchar(13),@cont varchar(8),@utilizator varchar(8),@abonat_fact varchar(13),@docXML xml,@contract_fact varchar(13),
        @casier_inc varchar(13),@suma_inc float,@data_fact datetime, @nr_doc_inc int,@id_fact int,@mesaj varchar(200),@nrchit char(8),@nrtemp int, @inXML varchar(1),
        @nr_fact_avans varchar(13),@id_fact_avans int,@suma_incasata_total float,@sold_total bit,@contract_avans int,@formular varchar(20)
begin try
exec wIaUtilizator @sesiune, @utilizator output
select	@abonat = isnull(@parXML.value('(/parametri/@abonat)[1]','varchar(13)'),''),	
		@contract_avans = isnull(@parXML.value('(/parametri/@contract_avans)[1]','int'),0),	
		@tip_inc = isnull(@parXML.value('(/parametri/@tip_inc)[1]','varchar(2)'),''),
		@suma_inc = isnull(@parXML.value('(/parametri/@suma_inc)[1]','float'),0),
        @data_inc=ISNULL(@parXML.value('(/parametri/@data_inc)[1]', 'datetime'), ''),
        @casier_inc = isnull(@parXML.value('(/parametri/@casier)[1]','varchar(13)'),''),
        @nr_doc_inc = isnull(@parXML.value('(/parametri/@nr_doc_inc)[1]','int'),0),
        @sold_total = isnull(@parXML.value('(/parametri/@sold_total)[1]','bit'),0),
        @inXML = @parXML.value('(/parametri/@inXML)[1]','varchar(1)')
 
	if @sold_total=1
		set @suma_inc=isnull((select SUM(sold) from FactAbon where abonat=@abonat and data<=@data_inc and tip not in ('AV','AP')),0)
   
	set @suma_incasata_total=@suma_inc   
   	
   if @tip_inc =''
	set @tip_inc=ISNULL((select tip_incasare from Casieri where Cod_casier=@utilizator),'')
	   
   if @tip_inc =''
		begin
			set @mesaj='Tipul de incasare nu a fost introdus!!'
			Raiserror(@mesaj,11,1)
		end		
   
   if @suma_inc<=0
	if @sold_total=1
	    begin
			set @mesaj='Abonatul selectat are sold '+convert(varchar,@suma_inc)+'!!'
			Raiserror(@mesaj,11,1)	    
	    end
	    else
		begin
			set @mesaj='Suma de incasat trebuie sa fie mai mare de 0!!'
			Raiserror(@mesaj,11,1)
		end	
  
   if @nr_doc_inc=0
   begin
		exec wIauNrDocUA 'UI',@utilizator,'' ,@nrtemp output
		if @nrtemp>99999999
			begin
			set @mesaj='Eroare la obtinerea nr. de document!'
			raiserror(@mesaj,11,1)
			end
		if @nrtemp=0
			begin
			set @mesaj='Eroare la obtinerea nr. de document!'
			raiserror(@mesaj,11,1)
			end
		else
			set @nr_doc_inc=(CAST(@nrtemp as CHAR(8)))
			
	end 
	
	select @formular =case when (@suma_inc<=(isnull((select SUM(sold) from FactAbon where abonat=@abonat and data<=@data_inc and tip not in ('AV','AP')),0)))then rtrim(Formular_chitanta) 
   	                       when (@suma_inc>(isnull((select SUM(sold) from FactAbon where abonat=@abonat and data<=@data_inc and tip not in ('AV','AP')),0))) 
   	                           and (isnull((select SUM(sold) from FactAbon where abonat=@abonat and data<=@data_inc and tip not in ('AV','AP')),0)>0.01 ) then rtrim(Formular_chitanta_sold_avans)
   						   when (isnull((select SUM(sold) from FactAbon where abonat=@abonat and data<=@data_inc and tip not in ('AV','AP')),0)=0 ) then rtrim(Formular_chitanta_avans)
   	                  else '' end 
   	from casieri
   	where Cod_casier=@utilizator
	
	set @cont=ISNULL((select RTRIM(cont_specific) from tipuri_de_incasare where ID=@tip_inc),'')
	
	if @formular =''
		begin
			set @mesaj='Formularul nu a fost configurat !!'
			Raiserror(@mesaj,11,1)
		end		
 
	declare facturi_cu_sold cursor                      
	for select distinct id_factura,sold,abonat,contract,penalizari,loc_de_munca ,data
	from factAbon          
	where abonat=@abonat  and sold>0.001 and data<=@data_inc and tip not in ('AV','AP')    
	order by data  
	open facturi_cu_sold                     
	fetch next from facturi_cu_sold 
              into @id_fact,@sold_fact,@abonat_fact,@contract_fact,@penalizari_fact,@loc_de_munca_fact,@data_fact           
  
    while  @@fetch_status = 0   and @suma_inc>0.001    
    begin      		
    
    if @suma_inc>=@sold_fact
		begin

		exec UAScriuIncasare 'IF',@tip_inc,@nr_doc_inc output,@data_inc,@abonat,@loc_de_munca_fact,@id_fact,@sold_fact,0,0,@utilizator,0,@utilizator,0,''
		set @suma_inc=@suma_inc-@sold_fact
		end
	else
		if @suma_inc<@sold_fact and @suma_inc>0
			begin
				exec UAScriuIncasare 'IF',@tip_inc,@nr_doc_inc output,@data_inc,@abonat,@loc_de_munca_fact,@id_fact,@suma_inc,0,0,@utilizator,0,@utilizator,0,''
				set @suma_inc=0
			end 
	 
	 fetch next from facturi_cu_sold 
              into @id_fact,@sold_fact,@abonat_fact,@contract_fact,@penalizari_fact,@loc_de_munca_fact ,@data_fact                     
	end                     
    close facturi_cu_sold                   
    deallocate facturi_cu_sold
    
    if @suma_inc>0.001
    begin 	
    	exec UAScriuAvans @abonat,@suma_inc,@data_inc,@contract_avans,@utilizator,@utilizator,'',@tip_inc,'AV',@nr_doc_inc output,@nr_fact_avans output,@id_fact_avans output,0
    	
    end
    
    --formular
    
    declare @DelayLength char(8)= '00:00:01'
    WAITFOR delay @DelayLength
    declare @p2 xml,@paramXmlString varchar(max)
    set @paramXmlString= (select 'IA' as tip, @formular as nrform,@abonat as tert, rtrim(@nr_doc_inc) as numar, rtrim(@nr_doc_inc) as factura, @data_inc as data, @inXML as inXML for xml raw )
    exec wTipFormular @sesiune, @paramXmlString
    
    
    select 'S-a incasat suma '+rtrim(convert(varchar,@suma_incasata_total))+'RON, pe chitanta cu numarul '+rtrim(@nr_doc_inc)+' !' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end

--select * delete from IncasariFactAbon where Casier=''
--select * from incasariFactAbon
--select * from webconfigtipuri
