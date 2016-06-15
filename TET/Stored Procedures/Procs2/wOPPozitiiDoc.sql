
create procedure wOPPozitiiDoc @sesiune varchar(50), @parXML xml
as

declare @mesaj varchar(max)

begin try
	declare @numar varchar(10), @data datetime, @gestiune varchar(20), @tert varchar(20), @lm varchar(10),
			@factura varchar(20), @datafacturii datetime, @datascadentei datetime, @dengestiune varchar(100), 
			@dentert varchar(100), @denlm varchar(100), @CUIfurnizor varchar(20), @xml xml,
			@cod varchar(20), @cantitate float, @pretfaraTVA float, @TVApepozitie float, @count int, @max int

	set @numar = isnull(@parXML.value('(/parametri/DateGrid/row/parametri/@numar)[1]','varchar(20)'),'')
	set @data = isnull(@parXML.value('(/parametri/DateGrid/row/parametri/@data)[1]','datetime'),getdate())
	set @gestiune = isnull(@parXML.value('(/parametri/DateGrid/row/parametri/@gestiune)[1]','varchar(20)'),'')
	set @dengestiune = isnull(@parXML.value('(/parametri/DateGrid/row/parametri/@dengestiune)[1]','varchar(100)'),'')
	set @tert = isnull(@parXML.value('(/parametri/DateGrid/row/parametri/@tert)[1]','varchar(20)'),'')
	set @dentert = isnull(@parXML.value('(/parametri/DateGrid/row/parametri/@dentert)[1]','varchar(100)'),'')
	set @lm = isnull(@parXML.value('(/parametri/DateGrid/row/parametri/@lm)[1]','varchar(20)'),'')
	set @denlm = isnull(@parXML.value('(/parametri/DateGrid/row/parametri/@denlm)[1]','varchar(100)'),'')
	set @factura = isnull(@parXML.value('(/parametri/DateGrid/row/parametri/@factura)[1]','varchar(20)'),'')
	set @datafacturii = isnull(@parXML.value('(/parametri/DateGrid/row/parametri/@datafacturii)[1]','datetime'),getdate())
	set @datascadentei = isnull(@parXML.value('(/parametri/DateGrid/row/parametri/@datascadentei)[1]','datetime'),getdate())
	set @CUIfurnizor = isnull(@parXML.value('(/parametri/DateGrid/row/parametri/@CUIfurnizor)[1]','varchar(20)'),'')
	
	if object_id('tempdb..#pozitii') is not null
		drop table #pozitii

	select	row_number() over (order by t.c.value('@codfurnizor','varchar(20)')) as Row,
			rtrim(t.c.value('@codfurnizor','varchar(20)')) codfurnizor,
			rtrim(t.c.value('@cod','varchar(20)')) cod,
			rtrim(t.c.value('@denumire','varchar(100)')) denumire,
			convert(decimal(18,3),t.c.value('@cantitate','float')) cantitate,
			convert(decimal(18,5),t.c.value('@pretfaraTVA','float')) pvaluta,
			convert(decimal(18,2),t.c.value('@TVApepozitie','float')) sumatva,
			'RM' subtip
		into #pozitii
	from @parXML.nodes('/parametri/DateGrid/row') t(c)
	left join ppreturi p on p.CodFurn=t.c.value('@codfurnizor','varchar(20)') and p.Tert=@tert
	where t.c.value('@selectare','bit') = 1
	
	if exists (select * from #pozitii where isnull(cod,'')='')
		raiserror('Exista pozitii fara cod de nomenclator preluat. Factura nu poate fi importata.', 16, 1)

	set @mesaj=null
	select @mesaj = isnull(@mesaj+char(10), 'Urmatoarele linii nu au cod de nomenclator valid: ')+
		rtrim(p.cod) + ' - ' +rtrim(p.denumire)
	from #pozitii p 
	where not exists (select * from nomencl n where n.cod=p.cod)
	
	if len(@mesaj)>0
	begin
		set @mesaj=@mesaj+char(10) + 'Factura nu poate fi importata.'
		raiserror(@mesaj, 16,1)
	end
	
	if not exists (select * from #pozitii)
		raiserror('Nu exista nicio pozitie de scris in baza de date!', 16, 1)

	-- Se insereaza in ppreturi pozitiile care nu exista
	set @count = 1
	set @max = (select max(Row) from #pozitii)
	while @count <= @max
	begin
		if not exists(select 1 from ppreturi where tert=@tert and CodFurn=(select codfurnizor from #pozitii where Row=@count) and Cod_resursa=(select cod from #pozitii where Row=@count))
			insert into ppreturi(	Tip_resursa,
									Cod_resursa,
									Tert,
									UM_secundara,
									Coeficient_de_conversie,
									Pret,
									Data_pretului,
									CodFurn,
									Nr_zile_livrare,
									Cant_minima
								)
			select 		'C',
						(select cod from #pozitii where Row=@count),
						@tert,
						'',
						0,
						(select pvaluta from #pozitii where Row=@count),
						getdate(),
						(select codfurnizor from #pozitii where Row=@count),
						0,
						0
				  
		set @count = @count + 1
	end

	set @xml = (select	@numar as numar,
						@data as data,
						@gestiune as gestiune,
						@dengestiune as dengestiune,
						@tert as tert,
						@dentert as dentert,
						@lm as lm,
						@denlm as denlm,
						@factura as factura,
						@datafacturii as datafacturii,
						@datascadentei as datascadentei,
						'RM' as tip,
						(select * 
						from #pozitii 
						for xml raw, type)
				for xml raw)
	
	if exists(select 1 from sysobjects where name='wScriuDoc')	
		exec wScriuDoc @sesiune=@sesiune, @parXML=@xml
	else
		if exists(select 1 from sysobjects where name='wScriuDocBeta')
		exec wScriuDocBeta @sesiune=@sesiune, @parXML=@xml
end try

begin catch
	set @mesaj = error_message() + ' (wOPPozitiiDoc)'
	raiserror(@mesaj, 11, 1)
end catch
