/* Prelucreaza descrierea coloanelor unui indicatori */
CREATE procedure wStergColoaneIndicator  @sesiune varchar(50), @parXML XML
as

declare @codInd varchar(10), @update smallint, @nivel smallint, @denumire varchar(50), @tipGrafic smallint, @proceduraDate varchar(200), @o_nivel smallint

begin try

	select	@codInd = @parXML.value('(/row/@cod)[1]', 'varchar(10)'),
			@nivel = isnull(@parXML.value('(/row/row/@nivel)[1]', 'smallint'),-1)

	delete from colind where Cod_indicator = @codInd and colind.Numar=@nivel
	
end try
begin catch
	declare @msgEroare varchar(2000)
	set @msgEroare=ERROR_MESSAGE()+'(wStergColoaneIndicator)'
	raiserror (@msgEroare, 11, 1)
end catch
