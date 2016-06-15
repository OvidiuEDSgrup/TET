
CREATE procedure wIaCorespondenteNomenclator @sesiune varchar(50), @parXML xml
as

declare	@cod varchar(20), @utilizator varchar(20), @mesaj varchar(100)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	select @cod = upper(@parXML.value('(/row/@cod)[1]','varchar(20)'))

	select	
		rtrim(c.Cod_corespondent) as codcoresp, rtrim(n.Denumire) as dencodcoresp, c.detalii detalii
	from corespondente c
	inner join nomencl n on n.cod=c.cod_corespondent
	where c.cod=@cod
	for xml raw, root('Date')

	select '1' as areDetaliiXml for xml raw, root('Mesaje')

end try	

begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
