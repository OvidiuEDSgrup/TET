--***
create procedure wOPStornareDocumentSP1 @sesiune varchar(50), @parXML xml output
as
declare @eroare varchar(1000),@xml xml, @numarDoc varchar(100),@dataDoc datetime,@tipDoc varchar(10)
	,@tert varchar(20),@data_facturii datetime,@factura varchar(20)
	,@idantetbon int, @faraGenerarePlin int, @sumaPD float, @parXmlOPBon xml, @docRE xml
	,@cont_casa varchar(20), @utilizator varchar(20)
	
set @eroare=''
begin try
	--citire numar/data document generate prin "wScriuDoc".
	SELECT	@numarDoc=ISNULL(@parXML.value('(/*/@numar)[1]', 'VARCHAR(13)'), ''),
			@dataDoc=ISNULL(@parXML.value('(/*/@data)[1]', 'DATETIME'), ''),
			@tipDoc=ISNULL(@parXML.value('(/*/@tip)[1]', 'varchar(10)'), '')
			
	if OBJECT_ID('tempdb..#yso_wOPStornareDocument') is not null
		select top (1) @parXmlOPBon=parXML from #yso_wOPStornareDocument s

	select @idantetbon=ISNULL(@parXmlOPBon.value('(/*/@idantetbon)[1]', 'int'), 0)
		,@faraGenerarePlin = isnull(@parXmlOPBon.value('(/*/@faraplin)[1]','int'),0)
		,@cont_casa = isnull(@parXmlOPBon.value('(/*/@contcasa)[1]','varchar(20)'),0)
		
	if @idantetbon<>0 and @faraGenerarePlin=0 
	begin		
		select @tert=max(tert), @factura=max(factura), @data_facturii=max(Data_facturii)
			,@sumaPD=-SUM(cantitate*Pret_vanzare+TVA_deductibil)--SUM(cantitate*Pret_cu_amanuntul)
		from PozDoc where Subunitate='1' and tip=@tipDoc and numar=@numarDoc and data=@dataDoc

		declare @numar_bon varchar(20), @data_bon varchar(10)

		select 
			@numar_bon=convert(varchar(10),Numar_bon), @data_bon=convert(varchar(10),Data_bon,103)
		from antetBonuri where IdAntetBon=@idantetbon

		set @docRE=
			(SELECT
				@cont_casa cont, convert(varchar(10), @dataDoc,101) data,'RE' tip, 
				(select
					'AP'+@numarDoc numar, convert(decimal(15,2),@sumaPD) suma,  'PS' subtip,
					'Stornare bon '+ isnull(@numar_bon+ ' din data '+@data_bon,'') explicatii, @tert tert, @numarDoc factura
				for XML raw, TYPE)
			for xml RAW)

		exec wScriuPozplin @sesiune=@sesiune, @parXML=@docRE
		
		SELECT 'S-a generat cu succes documentul storno tip AP '+RTRIM(@numarDoc)+' din data de '+LTRIM(CONVERT(VARCHAR(20),@dataDoc,103))
			+(case when @faraGenerarePlin=0 then ' si Plata de Stornare pe aceeasi data' else '' end) AS textMesaj for xml raw, root('Mesaje') 
	end

	--select top 1 @tert=tert, @factura=factura, @data_facturii=Data_facturii
	--from pozdoc 
	--where numar=@numarDoc and tip=@tipDoc and data=@dataDoc

	--set @xml=
	--	(select @numarDoc as numar, @factura factura, convert(char(10),@data_facturii,101) as data_facturii, convert(char(10),@dataDoc,101) as data, @tipDoc as tip,
	--		@tert as tert, 'DISPPLDOC' nrform
	--	for xml raw)
	
	----select @xml
	--exec wTipFormular @sesiune=@sesiune,@parXML=@xml
end try
begin catch
	set @eroare=ERROR_MESSAGE() + ' (wOPStornareDocumentSP1)'
end catch

if len(@eroare)>0 
	raiserror(@eroare,16,1)

/*
exec wOPStornareDocumentSP1 @sesiune='14F5269AE5811',@parXml='<row numar="900001" tip="AP" data="2015-03-10"/>'
*/