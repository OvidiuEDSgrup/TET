create procedure wStergTipTVATert @sesiune varchar(50), @parXML xml
as
BEGIN TRY
	declare @id_tva_pe_tert int, @mesaj varchar(max)

	set @id_tva_pe_tert=@parXML.value('(/*/*/@id_tva_pe_tert)[1]','int')

	delete from TvaPeTerti where idTvaPeTert=@id_tva_pe_tert

end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wStergTipTVATert)'
	raiserror(@mesaj, 11, 1)
end catch
