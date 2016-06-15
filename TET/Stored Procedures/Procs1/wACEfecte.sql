
CREATE procedure wACEfecte @sesiune varchar(50), @parXML XML  
as  

	declare 
		@searchText varchar(100), @tert varchar(13),@raport varchar(100),@subtip varchar(2), @parXMLef xml,
		@tipefect varchar(1)

	SELECT
		@searchText=replace(isnull(@parXML.value('(/row/@searchText)[1]','varchar(100)'),'%'),' ','%'),
		@tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''),
		@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''),
		@raport=ISNULL(@parXML.value('(/row/@raport)[1]', 'varchar(100)'), ''),
		@tipefect = NULLIF(@parXML.value('(/row/@tipefect)[1]', 'varchar(100)'),''),
		@parXMLef=(select @sesiune sesiune for xml raw)

	IF @tipefect IS NULL
		select @tipefect=LEFT(@subtip,1)

	/**	daca suntem pe macheta unui raport sau nu exista proprietatea 'LOCMUNCA' pentru utilizatorul curent se iau pur si simplu efectele*/
	if (rtrim(@raport)<>'' or dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=0)	
	begin	
		select top 100 
			rtrim(e.Nr_efect) as cod,isnull(rtrim(e.Explicatii),'')+ ', '+convert(char(10),e.data,101) +', Tip:'+rtrim(e.Tip) as denumire,  
			'Sold: '+convert(varchar(20),(CONVERT (decimal(17,3),e.Sold)))+ ' Cont: '+RTRIM(cont)  as info		 
		from efecte e
		where (e.Nr_efect like @searchText+'%' or e.Explicatii like '%'+@searchText+'%'  )
			and (@tert='' or e.Tert=@tert)
			and (@raport<>'' or e.sold>0.001)
			and (@raport<>'' or e.Tip=@tipefect)
		order by rtrim(e.Nr_efect)	
		for xml raw
	end
	else 
		if @tert='' /**	altfel se iau doar acele efecte pentru care exista date pe locul de munca filtrat*/
			select top 0 '' as cod, '' as denumire for xml raw
		else
			select top 100 
				rtrim(e.efect) as cod, 'Sold: '+convert(varchar(20),(CONVERT (decimal(17,3),e.valoare-e.achitat)))+ ' Cont: '+RTRIM(cont)  as info,
				isnull(rtrim(e.Explicatii),'')+', '+convert(char(10),e.data,101)+', Tip:'+rtrim(e.Tip_efect) as denumire
			from fEfecte('1901-1-1','2500-1-1',null,@tert,'',null,null,null, @parXMLef) e
			where 
				(e.efect like @searchText+'%' or e.Explicatii like '%'+@searchText+'%')  				
				and e.valoare-e.achitat>0.001 
				and e.tip_efect=@tipefect
			order by rtrim(e.efect) 
			for xml raw
