
create procedure wIaPozListaCoduriBare @sesiune varchar(50), @parXML xml
as

	declare @utilizator varchar(100),@refresh varchar(5)

	SET @refresh = isnull(@parXML.value('(/row/@_refresh)[1]', 'varchar(5)'), '1')

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	if @refresh='0'
	BEGIN
		/** La prima intrare in macheta (refresh=0) sterg datele pt utilizatorul curent si deschid macheta de PREFILTRARE care va popula tabelul **/
		SELECT 'Populare lista coduri de bare' nume, 'LB' codmeniu, 'LB' tip,'PF' subtip,'O' tipmacheta,
					(SELECT @parXML ) dateInitializare
		FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
		return
	END

	select 
		rtrim(t.cod) cod, RTRIM(n.denumire) denumire, convert(decimal(12,2),pret) as pret,convert(decimal(12,2),pretvechi) as pretvechi
	from temp_ListareCodBare t 
	JOIN nomencl n on n.cod=t.cod 
	where t.utilizator=@utilizator
	for XML RAW, ROOT('Date')
