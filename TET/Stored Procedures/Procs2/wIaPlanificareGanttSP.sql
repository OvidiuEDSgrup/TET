--***
create procedure wIaPlanificareGanttSP @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@datajos datetime, @datasus datetime, @cautare varchar(100)

	select
		@datajos = isnull(@parXML.value('(/*/@datajos)[1]', 'datetime'), '01/01/1901'),
		@datasus = isnull(@parXML.value('(/*/@datasus)[1]', 'datetime'), '01/01/2999'),
		@cautare = '%' + rtrim(ltrim(isnull(@parXML.value('(/*/@_cautare)[1]', 'varchar(100)'), '%'))) + '%'

	select 
		rtrim(p.denumire) + ' (' + rtrim(convert(varchar(10), p.postul_de_lucru)) + ')' as utilaj,
		rtrim(convert(varchar(10), p.postul_de_lucru)) as cod_masina, rtrim(p.denumire) as tooltiputilaj,
		(
			select
				convert(varchar(10), prg.Data_planificarii, 101) as dataStart,
				convert(int, substring(prg.Ora_planificarii_start, 1, 2)) as oraStart,
				convert(varchar(10), prg.Data_planificarii_stop, 101) as dataStop,
				convert(int, substring(prg.Ora_planificarii_stop, 1, 2)) as oraStop,
				rtrim(prg.Cod) as operatie,
				rtrim(isnull(prg.Descriere_problema, '')) as denoperatie,
				'L' AS stare,
				'In lucru' as starecomanda,
				'Nr. inmatriculare: ' + rtrim(isnull(prg.nr_inmatriculare_prog, '')) + char(13) + 
					'Nume: ' + rtrim(isnull(prg.nume_prog, '')) + char(13) +
					'Telefon: ' + (case when isnull(prg.telefon_prog, '') <> '' then rtrim(prg.telefon_prog) else 'nu are' end) + char(13) + 
					'Nr. deviz: ' + rtrim(prg.Deviz) as info,
				rtrim(isnull(prg.Numar_curent, '')) as comanda,
				'' as tooltip,
				'Productie' as tipcomanda,
				(case when isnull(prg.Deviz, '') = '' then 'X' else 'P' end) as tip,
				rtrim(prg.Deviz) as deviz,
				rtrim(p.Postul_de_lucru) as post_lucru,
				rtrim(p.Denumire) as denpost_lucru
			from Programator prg
			where (prg.Data_planificarii between @datajos and @datasus or prg.Data_planificarii_stop between @datajos and @datasus)
				and prg.Postul = p.Postul_de_lucru
				and (prg.nume_prog like @cautare or prg.Descriere_problema like @cautare)
			for xml raw('Operatie'), root('Planificari'), type
		)
	from Posturi_de_lucru p
	for xml raw('Resursa'), root('Date')

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
