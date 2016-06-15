--***
CREATE procedure wIaGrupeProdusePv @sesiune varchar(40), @parXML xml
as
declare @returnValue int, @msgEroare varchar(1000)
if exists(select * from sysobjects where name='wIaGrupeProdusePvSP1' and type='P')      
begin
	exec @returnValue = wIaGrupeProdusePvSP1 @sesiune=@sesiune,@parXML=@parXML output
	if @parXML is null
		return @returnValue 
end

begin try
	declare @grupa varchar(13), @gestiune varchar(20), @gestutiliz varchar(20), @categoriePret int, 
			@cSub char(9), @utilizator varchar(20), @preturi int, 
			@nrElemente int, @start int

	/*
	TODO: 
		- de gandit un flag prin care sa se poata alege grupele care vor fi trimise spre PV - probabil nu toate trebuie...
		- grupe pe nivele
	*/

	--A,F,M,O,P,R,S
	--Marfa,Mijloace fixe,Material,Obiecte de inventar,Produs,Servicii furnizate,Servicii prestate

	declare @areGRORD int,@arePoze int
	select @arePoze=1
	select @arePoze=(select val_logica from par where tip_parametru='PV' and parametru='TAREPOZA')
	
	if exists(select 1 from proprietati pr where pr.tip='GRUPA' and pr.cod_proprietate='GRORD' and pr.valoare<>'')
		set @areGRORD=1
	else 
		set @areGRORD=0

	select	@nrElemente = isnull(@parXML.value('(/row/@numarvizibil)[1]','int'), 999),
			@start = isnull(@parXML.value('(/row/@start)[1]','int'), 1)

	declare @grupe table (nr int, grupa varchar(20), denumire varchar(200), poza varchar(2000), nrproduse int, valoare varchar(50))

	insert @grupe(nr, grupa, denumire, nrproduse, valoare, poza)
		select	top(@nrElemente) nr, 
				rtrim(g.Grupa), 
				convert(varchar(30), nr)+' '+rtrim(g.Denumire), 
				convert(varchar(30),g.nrprod), 
				'',--convert(varchar(30),g.nrprod)+' produse', 
				(case when @arePoze=1 then '/assets/img/folder_orange.png' else null end)
		from
			(select g.grupa, 
					g.Denumire, 
					n.nrprod,
					ISNULL(pr.valoare,'99') nrord,
					ROW_NUMBER() over(order by (ISNULL(pr.valoare,g.denumire))) nr
				from grupe g
				inner join (select n.grupa, count(*) nrprod from nomencl n group by grupa) n on n.Grupa=g.grupa
				left outer join proprietati pr on pr.tip='GRUPA' and pr.cod_proprietate='GRORD' and pr.cod=g.grupa and pr.valoare<>''
				where (@areGRORD=0 or pr.valoare is not null)
			) g
		where nr>=@start
		order by nrord
		
		-- iau poza grupelor
		update g
			set poza=pozeria.Fisier
		from @grupe g, pozeRIA 
		where pozeria.Tip='G' and pozeria.cod=g.grupa
		
		-- inserez produsele in forma xml
		insert into #articolePv(rownumber, xmlData)
			select nr, x.*
				from @grupe g
				CROSS APPLY
				(
					SELECT 
						(
							SELECT * 
							FROM @grupe gx
							WHERE g.nr = gx.nr
							FOR XML RAW
						) gx1
				)x
		
	--select rtrim(g.Grupa) grupa, rtrim(max(g.Denumire)) dengrupa, rtrim(max(g.Denumire)) denumire, isnull(convert(varchar(30),COUNT(n.cod)),'0')+' prod.' as valoare, 
	--	isnull(COUNT(n.cod),0) as nrproduse, /* daca acest numar este > 0, PV considera linia ca grupa, si face drill-down 
	--		daca nrproduse=0 sau null, linia e considerata produs */
	--	isnull(max(pozeria.fisier),'/assets/img/folder_orange.png') as poza
	--	from grupe g
	--	inner join nomencl n on n.Grupa=g.Grupa
	--	left outer join PozeRIA on pozeria.tip='G' and pozeria.cod=g.Grupa
	--	where
	--	g.Tip_de_nomenclator in ('A','M','P','R','S')
	--	group by g.Grupa
	--	order by 2
	--	for xml raw

end try
begin catch
set @msgEroare=ERROR_MESSAGE()+'(wIaGrupeProdusePv)'
raiserror(@msgEroare,11,1)
end catch	
