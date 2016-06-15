/*

*/
CREATE PROCEDURE wmIaDispozitiiLivrare @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wmIaDispozitiiLivrareSP')
begin 
	declare @returnValue int
	exec @returnValue = wmIaDispozitiiLivrareSP @sesiune, @parXML output
	return @returnValue
end

begin try
	declare @tip varchar(50), @utilizator varchar(50), @mesaj varchar(1000), @xmlDisp xml, @xmlNou xml, @xmlPreluare xml, @denTip varchar(50)

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	
	-- citesc tipul dispozitiilor afisate
	select	@tip = @parXML.value('(/*/@tipdisp)[1]', 'varchar(50)'),
			@denTip = (case @tip when 'AP' then 'Factura' when 'TE' then 'Transfer' else @tip end)

	if @tip is null
		raiserror('Eroare configurare: Nu s-a trimis in XML tipul dispozitiilor filtrate.',16,1)

	-- dispozitii deja existente
	set @xmldisp=
		(select TOP 25
			idDisp as cod, 
			descriere as denumire,
			'Numar '+@denTip+': '+detalii.value('/row[1]/@numar', 'varchar(50)') info, -- dupa generare in pozdoc, afisez in info numarul documentului generat
			(case a.stare when 'Finalizata' then '0xF3E7E7' else null end ) culoare
		from AntDisp a
		where a.tipDisp = @tip
		and DATEDIFF(month, a.dataUltimeiOperatii, GETDATE())=0
		order by idDisp desc
		for xml raw)
	
	-- xml pentru adaugare dispozitie noua 'goala'
	set @xmlNou = (select 'Adaug dispozitie noua' denumire, @denTip info, 'assets/Imagini/Meniu/AdaugProdus32.png' as poza for xml raw)
	
	-- xml pentru creare dispozitie noua pornind de la o comanda de livrare
	set @xmlPreluare = (select 'Preluare comanda livrare' denumire, @denTip info, 'assets/Imagini/Meniu/AdaugProdus32.png' as poza, '1' stare, '1' _toateAtr, 
							'1' [wmIaComenzi.faraFiltruUtilizator], '1' [wmIaComenzi.viewNeimportant], 'C' [wmIaComenzi.tipdetalii], 
							'wmIaComenzi' procdetalii, 'wmImportComandaDispLivrare' as [wmIaComenzi.procdetalii] for xml raw)
	
	select @xmlNou, @xmlPreluare, @xmlDisp for xml raw('Date')
	
	select 'wmIaPozDispLivrare' as procdetalii, 'C' as tipmacheta, '@iddisp' as _numeAtr, 'Dispozitii '+@denTip titlu
	for xml raw, root('Mesaje')
	
	-- 'In lucru'

end try
BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wmIaDispozitiiLivrare)'
END CATCH

IF LEN(@mesaj) > 0
	RAISERROR (@mesaj, 16, 1)
