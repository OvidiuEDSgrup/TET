
create procedure wACPNomencl @sesiune varchar(50), @parXML XML  
as
	declare 
		@searchText varchar(50),@subtip varchar(20),
		@tip varchar(20), @codTehn varchar(20)
		set @searchText='%'+replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),' ' ,'%')+'%'
		set @tip=ISNULL(@parXML.value('(/row/@tip_tehn)[1]', 'varchar(20)'), '')
		set @codTehn=ISNULL(@parXML.value('(/row/@cod_tehn)[1]', 'varchar(20)'), '')
		set @subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(20)'), '')

	
	--Reper in antet macheta tehnologii
	if @tip in ('Reper','Multipla','Interventie') and @subtip=''
		select 'fara cod' as cod, @codTehn as denumire,'' as info
		for xml raw,root('Date')
	else	
		--Serviciu in antet macheta tehnologii
		if @tip='Serviciu' and @subtip=''
					select RTRIM(cod) as cod, RTRIM(denumire) as denumire, 'UM: '+RTRIM(um) as info
					from nomencl
					where tip='S'
					for xml raw,root('Date')
		else
			--Materiale, semifabricate sau produse in antet sau pozitii
			select top 100
				RTRIM(cod) as cod, RTRIM(denumire) as denumire, 'UM: '+RTRIM(um) as info
			from nomencl 
			where tip='P' and (cod like @searchText or Denumire like @searchText) 
			for xml raw,root('Date')
