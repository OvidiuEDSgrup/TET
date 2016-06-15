
CREATE PROCEDURE wStergUtilizatoriED @sesiune VARCHAR(50), @parXML XML
AS
begin
declare @eroare varchar(2000)
begin try
	DECLARE @utilizator VARCHAR(50), @codprop VARCHAR(50)

	SET @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(50)')
	--> verificare pt grupe:
	declare @primUtilizatorGrupa varchar(50), @eGrupa bit
	select @eGrupa=1 from utilizatori g where g.ID=@utilizator and g.marca='GRUP'
	select top 1 @primUtilizatorGrupa=u.id
		from utilizatori u
			inner join grupeUtilizatoriRia gr on u.ID=gr.utilizator
			inner join utilizatori g on g.ID=gr.grupa and g.ID=@utilizator and g.marca='GRUP'

	if @primUtilizatorGrupa is not null
	begin
		select @eroare='Grupa are asociat cel putin un utilizator! ('+@primUtilizatorGrupa+')'
		raiserror(@eroare,16,1)
	end

	DELETE
	FROM utilizatori
	WHERE ID = @utilizator

	DELETE
	FROM webConfigMeniuUtiliz
	WHERE IdUtilizator = @utilizator

	DELETE
	FROM webConfigRapoarte
	WHERE utilizator = @utilizator
	
	DELETE
	FROM grupeUtilizatoriRia
	WHERE utilizator = @utilizator

	DELETE
	FROM proprietati
	WHERE tip = 'UTILIZATOR'
		AND cod = @utilizator

	SELECT (case when @eGrupa=1 then 'Grupa ' else 'Utilizatorul ' end)+ @utilizator + 
		' a fost sters din baza de date. Au fost sterse si meniurile, rapoarte, grupele si proprietatile asociate lui!' AS textMesaj, 
		'Notificare' AS titluMesaj
	FOR XML raw, root('Mesaje')
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wStergUtilizatoriED '+convert(varchar(20),ERROR_LINE())+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)
end
