
CREATE PROCEDURE wScriuMeniuUtiliz @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @utilizator VARCHAR(50), @descriere VARCHAR(30), @sterg BIT, @adaug BIT, @modific BIT, @formulare BIT, 
	@operatii BIT, @drepturi VARCHAR(5), @update BIT, @codMeniu VARCHAR(20),@alocat bit

SET @utilizator = @parXML.value('(/row/@utilizator)[1]', 'varchar(50)')
SET @descriere = @parXML.value('(/row/@descriere)[1]', 'varchar(50)')
SET @sterg = @parXML.value('(/row/@dsterg)[1]', 'bit')
SET @adaug = @parXML.value('(/row/@dadaug)[1]', 'bit')
SET @modific = @parXML.value('(/row/@dmodific)[1]', 'bit')
SET @formulare = @parXML.value('(/row/@dformulare)[1]', 'bit')
SET @operatii = @parXML.value('(/row/@doperatii)[1]', 'bit')
SET @alocat = @parXML.value('(/row/@alocat)[1]', 'bit')
SET @codMeniu = isnull(@parXML.value('(/row/@id)[1]', 'varchar(20)'), '')
SET @update = isnull(@parXML.value('(/row/@update)[1]', 'bit'), 0)

SELECT @drepturi = (CASE WHEN @sterg = 1 THEN 'S' ELSE '' END) + (CASE WHEN @adaug = 1 THEN 'A' ELSE '' END) + (CASE WHEN @modific = 1 THEN 'M' ELSE '' END
		) + (CASE WHEN @formulare = 1 THEN 'F' ELSE '' END) + (CASE WHEN @operatii = 1 THEN 'O' ELSE '' END)

IF @update = 1
BEGIN
	IF exists (select 1 from webconfigmeniu m where m.meniu=@codMeniu and isnull(meniuparinte,'')='')
		--Director
	BEGIN
			DELETE w1
			FROM webConfigMeniuUtiliz w1
			INNER JOIN webConfigMeniu wcm ON w1.Meniu = wcm.Meniu
			WHERE w1.IdUtilizator = @utilizator
				AND (
					w1.meniu = @codMeniu
					OR wcm.MeniuParinte = @codMeniu
					)
		if @alocat=1
			INSERT INTO	webConfigMeniuUtiliz (IdUtilizator, IdMeniu, Drepturi, Meniu)
			SELECT @utilizator, NrOrdine, @drepturi, meniu
			FROM webConfigMeniu
			WHERE (
					meniu = @codMeniu
					AND nume = @descriere
					)
				OR MeniuParinte = @codMeniu
	END
	ELSE
	BEGIN
		DELETE
		FROM webConfigMeniuUtiliz
		WHERE idUtilizator = @utilizator
			AND Meniu = @codMeniu
		
		if @alocat=1
			INSERT INTO webConfigMeniuUtiliz(IdUtilizator, IdMeniu, Drepturi, Meniu)
		VALUES (@utilizator, 0, @drepturi, @codMeniu)
	END
	--> completare cu folder-ul care contine linia de meniu, daca nu era deja selectat:
	insert into webconfigmeniuutiliz(IdUtilizator, IdMeniu, Drepturi, Meniu)
	select @utilizator, 0, '', w.meniu
	from webconfigmeniu w --on u.Meniu=w.Meniu
		left join webconfigmeniuutiliz u on w.meniu=u.meniu and u.idutilizator=@utilizator
	where u.meniu is null and
		exists (select 1 from webconfigmeniu f inner join webconfigmeniuutiliz u on f.meniu=u.meniu
			where f.meniuparinte=w.meniu and u.IdUtilizator=@utilizator and f.meniu=@codMeniu
		)
	
END
ELSE
	SELECT 
		'Nu exista posibilitatea de a adauga meniuri noi in aceasta macheta! Toate meniurile definite pe baza de date se afla in tabel!' 
		textMesaj, 'Notificare' AS titluMesaj
	FOR XML raw, root('Mesaje')
