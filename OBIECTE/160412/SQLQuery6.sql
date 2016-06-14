declare @p2 xml, @parXML xml
set @p2=convert(xml,N'<row numardoc="SV910071" data="12/15/2015" cod="95900120" denumire="UNIS-Volant cu un brat" explicatii="211.SV 0000/00/00" cantitate="1.00" tipdocument="Necesar Aprovizionare" gestiune_primitoare="211.SV" gestiune="101" idPozContractCorespondent="541337" idPozContract="-415463" idContractCorespondent="1149" idContract="-60100" valoare="9.80" tipMacheta="D" codMeniu="YSO_FA" tip="FA" TipDetaliere="FA" subtip="GT"/>')

set @parXML=convert(xml,N'<row tipMacheta="D" codMeniu="YSO_FA" tip="FA" TipDetaliere="FA" subtip="GT"><row numardoc="SV910071" data="12/15/2015" cod="95900120" denumire="UNIS-Volant cu un brat" explicatii="211.SV                                  0000/00/00" cantitate="1.00" tipdocument="Necesar Aprovizionare" gestiune_primitoare="211.SV" gestiune="101" idPozContractCorespondent="541337" idPozContract="-415463" idContractCorespondent="1149" idContract="-60100" valoare="9.80"/><row numardoc="SV910071" data="12/15/2015" cod="95900118" denumire="UNIS-maner volant" explicatii="211.SV                                  0000/00/00" cantitate="1.00" tipdocument="Necesar Aprovizionare" gestiune_primitoare="211.SV" gestiune="101" idPozContractCorespondent="541338" idPozContract="-415462" idContractCorespondent="1149" idContract="-60100" valoare="4.28"/><row numardoc="SV910073" data="12/21/2015" cod="44841" denumire="UNIS-Invertor Airex  150/200 1KW" explicatii="211.SV                                  0000/00/00" cantitate="1.00" tipdocument="Necesar Aprovizionare" gestiune_primitoare="290.SV" gestiune="101" idPozContractCorespondent="541349" idPozContract="-415461" idContractCorespondent="1154" idContract="-60100" valoare="359.20"/></row>')
select @p2
--exec wOPGenerareTransferFundamenteComanda_p @sesiune='0D194BE41B353',@parXML=@p2

--;with antet as (
--		select idPozDocStorno = @parXML.value('(/*/@idContractCorespondent)[1]', 'int')
--			, idPozDocSursa = @parXML.value('(/*/@idContractCorespondent)[1]', 'int')
--			, tipS = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
--			, numarS = @parXML.value('(/*/@numardoc)[1]', 'varchar(20)')
--			, dataS = @parXML.value('(/*/@data)[1]', 'datetime')
--		)
	select --a.tipS, a.dataS, a.numarS
		 isnull(p.col.value('(@idContractCorespondent)[1]','int'),a.col.value('(@idContractCorespondent)[1]','int')) as idPozDocSursa
		, isnull(p.col.value('(@idContractCorespondent)[1]','int'),a.col.value('(@idContractCorespondent)[1]','int')) as idPozDocStorno
	--into #pozStorno
	from @parXML.nodes('/*') a(col)
		outer apply a.col.nodes('./row') p(col)