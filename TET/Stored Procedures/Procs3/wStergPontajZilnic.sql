--***
Create procedure wStergPontajZilnic @sesiune varchar(50), @parXML xml
as
Begin try

	begin transaction sterg_pontaj_zilnic

		declare @utilizator varchar(20), @data datetime, @datajos datetime, @datasus datetime, @marca varchar(6), @lm varchar(20), @mesaj varchar(1000), @docXMLIaPontajZilnic xml

		set @data = @parXML.value('(/*/@data)[1]', 'datetime')
		set @marca = isnull(@parXML.value('(/*/*/@marca)[1]', 'varchar(6)'),'')
		set @lm = isnull(@parXML.value('(/*/@lm)[1]', 'varchar(9)'),'')

		select @datajos=dbo.BOM(@data), @datasus=dbo.EOM(@data)

		delete from pontaj_zilnic
		where data between @datajos and @datasus and marca=@marca

		set @docXMLIaPontajZilnic = '<row datajos="' + convert(varchar(10),@datajos,101) + '" datasus="' + convert(varchar(10),@datasus,101) + '" lm="' + rtrim(@lm) +'"/>'
		exec wIaPozPontajZilnic @sesiune=@sesiune, @parXML=@docXMLIaPontajZilnic
	
	commit transaction sterg_pontaj_zilnic

End try

begin catch
	if EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'sterg_pontaj_zilnic')
		ROLLBACK TRAN sterg_pontaj_zilnic

	set @mesaj = error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 11, 1)
end catch
