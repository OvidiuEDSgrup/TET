--***
create procedure wOPRezervareStocBK_p @sesiune varchar(50), @parXML xml 
as  
begin try
	declare @REZSTOCBK int,@mesaj varchar(500),@gestiune_rez varchar(20),@dengest_rez varchar(50),@tert varchar(13),@numar varchar(20),
		@numar_doc varchar(13),@sub varchar(9),@gestiune_sursa varchar(20),@dengest_sursa varchar(50)
	
	exec luare_date_par 'GE', 'REZSTOCBK', @REZSTOCBK output, 0, @gestiune_rez output
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	
	select 
		@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
		@gestiune_sursa=ISNULL(@parXML.value('(/row/@gestiune)[1]', 'varchar(13)'), ''),
		@tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), '')
	
	set @dengest_rez= (select MAX(Denumire_gestiune) from gestiuni where Cod_gestiune=@gestiune_rez)	
	set @dengest_sursa= (select MAX(Denumire_gestiune) from gestiuni where Cod_gestiune=@gestiune_sursa)
	
	set @numar_doc=(select isnull(max(numar), '') as nr from pozdoc where subunitate=@sub and tip='TE'--and (:2=0 or data between ':3' and ':4') 
																	and numar like 'REZ%' /*and RTrim(factura)=RTrim(@numar)*/)
	if isnull(@numar_doc,'')='' 
		set @numar_doc='REZ00000'																
	declare @nr int
	set @nr=CONVERT(int,SUBSTRING(@numar_doc,4,8)+1)
	set @numar_doc=case when LEN(@nr)=1 then 'REZ0000'+CONVERT(varchar,@nr)
					  when LEN(@nr)=2 then 'REZ000'+CONVERT(varchar,@nr)	
					  when LEN(@nr)=3 then 'REZ00'+CONVERT(varchar,@nr)
					  when LEN(@nr)=4 then 'REZ0'+CONVERT(varchar,@nr)
					  when LEN(@nr)=5 then 'REZ'+CONVERT(varchar,@nr)end
	
	if @REZSTOCBK=0 
	begin
		select 'Nu au fost facute configurarile necesare lucrului cu gestiune pentru rezervari!' as textMesaj, 'Mesaj avertizare' as titluMesaj 
		for xml raw, root('Mesaje') 
	end
	
	select rtrim(@gestiune_rez) gestiune_rez,RTRIM(@dengest_rez) dengest_rez,@numar_doc numar_doc,rtrim(@gestiune_sursa) gestiune_sursa,
		RTRIM(@dengest_sursa) dengest_sursa
	for xml raw
end try	
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
--select * from gestiuni
