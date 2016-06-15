
create procedure wIaComenziDePrelucrat @sesiune varchar(50),@parXML xml
as
begin 
	declare
		@utilizator varchar(100), @f_tert varchar(200), @f_gestiune varchar(200), @f_agent varchar(200), @deschideMacheta bit

	select
		@f_tert			=	'%' +ISNULL(replace(@parXML.value('(/*/@f_tert)[1]','varchar(100)'),' ','%'),'%')+'%',
		@f_gestiune		=	'%' +ISNULL(replace(@parXML.value('(/*/@f_gestiune)[1]','varchar(100)'),' ','%'),'%')+'%',
		@f_agent		=	'%' +ISNULL(replace(@parXML.value('(/*/@f_agent)[1]','varchar(100)'),' ','%'),'%')+'%',
		@deschideMacheta=	ISNULL(@parXML.value('(/*/@deschidMacheta)[1]','bit'),1)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	IF OBJECT_ID('tmpComenziDePrelucrat') IS NULL
		create table tmpComenziDePrelucrat (utilizator varchar(100), idContract int)

	IF @deschideMacheta = 0
	BEGIN
		SELECT 
			'Filtrare comenzi de livrare'  nume, 'CECL' codmeniu, 'E' tipmacheta,'CE' tip,'PF' subtip,'O' fel
		FOR XML RAW('deschideMacheta'), ROOT('Mesaje')

		RETURN
	END

	SELECT
		c.numar comanda, rtrim(t.denumire) dentert, rtrim(c.tert) tert, rtrim(c.gestiune) gestiune, rtrim(g.Denumire_gestiune) dengestiune,
		convert(decimal(15,2), pozitii.valoare) valoare, pozitii.nr pozitii, 
		(case when c.detalii.value('(/*/@comanda)[1]','varchar(20)') IS NOT NULL then '#00FF00' else '#FF0000' end) as culoare,
		c.detalii.value('(/*/@comanda)[1]','varchar(20)') comanda_transport,tp.idContract idContract,rtrim(l.Denumire) as denlm
	FROM tmpComenziDePrelucrat tp
	JOIN Contracte c on c.idContract=tp.idContract
	left join lm l on l.Cod=c.loc_de_munca
	LEFT JOIN terti t on t.tert=c.tert
	LEFT JOIN gestiuni g on g.Cod_gestiune=c.gestiune
	OUTER APPLY 
	(
		SELECT 
			isnull(count(1), 0) nr, sum(cantitate * pret) AS valoare
		FROM PozContracte p
		where p.idContract=c.idContract
	) pozitii 
	where tp.utilizator=@utilizator and t.Denumire like @f_tert and g.Denumire_gestiune like @f_gestiune
	FOR XML RAW, ROOT('Date')
end
