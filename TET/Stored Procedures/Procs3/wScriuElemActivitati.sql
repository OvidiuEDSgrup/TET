--***
create procedure wScriuElemActivitati @parXML xml, @tip varchar(2)=null, @fisa varchar(10)=null, @data datetime=null, @numar_pozitie int=null, @idPozActivitati int=null
as

declare @eroare varchar(1000)
begin try
	if @idPozActivitati is null
	select @idPozActivitati=idPozActivitati from pozactivitati p
		where p.tip=@tip and p.fisa=@fisa and p.data=@data and p.numar_pozitie=@numar_pozitie
	
	if @idPozActivitati is null
		raiserror ('Nu s-a identificat pozitia din activitati!',16,1)

declare @elemTemp table (tip char(2), fisa varchar(30), data datetime, numar_pozitie int, element varchar(20), valoare float, tip_doc char(2), numar_doc varchar(20), data_doc datetime )

	/* scriu in tabela @elemTemp toate elementele din elemactivitati pt toate pozitiile */
	/* elementele trebuie sa existe in tabela 'elemente' (vezi inner join din query) */
insert into @elemTemp(tip, fisa, data, Numar_pozitie, element, valoare, tip_doc, numar_doc, data_doc)
select a.value('(../@tip)[1]', 'char(2)') AS tip,
	a.value('../@fisa[1]', 'varchar(20)') AS fisa,
	a.value('../@data[1]', 'datetime') AS data,
	a.value('(@numar_pozitie)[1]', 'int') AS nr_poz,
	rtrim(e.Cod) as element,
	isnull(a.value('(@valoare)[1]', 'float'),0) AS valoare,
	'','','01/01/1901'
from @parXML.nodes('row/row') as R(a)
	left join elemente e on (case when charindex('_',a.value('(@interventie)[1]', 'VARCHAR(100)'))<>0 then replace(rtrim(e.Cod),' ','_') else e.Cod end) = a.value('(@interventie)[1]', 'VARCHAR(100)') 
where a.value('(../@tip)[1]', 'char(2)')='FI'	--> datele se iau diferit pentru fise de interventie (FI)
union all										--> fata de fise de parcurs (FP) si fise de lucru (FL)
SELECT											-->
	T.n.value('tip[1]', 'char(2)') AS tip,
	T.n.value('fisa[1]', 'varchar(20)') AS fisa,
	T.n.value('data[1]', 'datetime') AS data,
	T.n.value('nr_poz[1]', 'int') AS nr_poz,
	rtrim(e.Cod) as element,
	T.n.value('value[1]', 'varchar(20)') AS val,
	'','','01/01/1901'
FROM 
( SELECT x.query('
	for $attr in /row/row/@*
	return
	<node>
	  <namespace>{ namespace-uri($attr) }</namespace>
	  <localname>{ local-name($attr) }</localname>
	  <value>{ data($attr) }</value>
	  <parent>{ local-name($attr/..) }</parent>
	  <tip>{ data($attr/../../@tip) }</tip>
	  <fisa>{ data($attr/../../@fisa) }</fisa>
	  <data>{ data($attr/../../@data) }</data>
	  <nr_poz>{ data($attr/../@numar_pozitie) }</nr_poz>
	</node>') AS nodes
	  FROM      @parXML.nodes('/row') x(x)
	) q1
	CROSS APPLY q1.nodes.nodes('/node') AS T ( n )
inner join elemente e on replace(rtrim(e.Cod),' ','_') = T.n.value('localname[1]', 'varchar(100)')
where T.n.value('tip[1]', 'char(2)')<>'FI' or (rtrim(e.Cod)) in ('OREBORD','ORENOU','KMBORD')

/* sterg toate elementele din elemactivitati */	
delete from elemactivitati where idPozActivitati=@idPozActivitati

INSERT INTO elemactivitati(Tip, Fisa, Data, Numar_pozitie, Element, Valoare,
	Tip_document, Numar_document, Data_document, idpozactivitati
)
select Tip, Fisa, Data, Numar_pozitie, Element, Valoare, tip_doc, numar_doc, data_doc, @idPozActivitati
	from @elemTemp
	where (tip='FI' or valoare<>0)
		
end try
begin catch
	--ROLLBACK TRAN
	declare @mesaj varchar(255)
	set @eroare=ERROR_MESSAGE()
	if @eroare is not null
		set @mesaj = @eroare+' (wScriuElemActivitati '+convert(varchar(10),ERROR_LINE())+')'
end catch

if object_id('tempdb..#test') is not null	--> pentru teste
	begin
		select * from #test
		drop table #test
	end

if (@mesaj is not null)
	raiserror(@mesaj,16,1)
