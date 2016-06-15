--*** Populare operatie cu grid pentru transferul de piese in gestiunea service ***
create procedure wOPGenerareTransferPiese_p @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@nrdeviz varchar(20), @detaliiPiese xml

	set @nrdeviz = isnull(@parXML.value('(/*/@nrdeviz)[1]', 'varchar(20)'), '')

	if @nrdeviz = ''
		raiserror('Nu s-a identificat devizul!', 16, 1)

	set @detaliiPiese = (
		select
			rtrim(n.denumire) as denumire,
			convert(decimal(17,3), p.Cantitate) as cantitate,
			convert(decimal(17,5), p.Tarif_orar) as tarif,
			convert(decimal(17,5), p.Pret_vanzare) as pretvanzare,
			convert(decimal(17,0), p.Discount) as discount,
			convert(decimal(17,2), round(p.Cantitate * p.Pret_vanzare * (1.00 - p.Discount/100) * (1.00 + p.Cota_TVA/100), 3)) as valoarecutva
		from pozdevauto p
		left join nomencl n on n.Cod = p.Cod
		where p.Cod_deviz = @nrdeviz
			and p.Tip_resursa = 'P'
			and p.Stare_pozitie = '1'
		for xml raw, type
	)

	select @detaliiPiese for xml path('DateGrid'), root('Mesaje')

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
