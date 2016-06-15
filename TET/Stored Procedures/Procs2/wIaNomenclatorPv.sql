/*
	aduce lista de produse din nomenclator, filtrate pe grupa aleasa - folosit in PVria cand se aleg produsele folosind interfata de touch.
*/
CREATE procedure wIaNomenclatorPv @sesiune varchar(40), @parXML xml
as
set transaction isolation level read uncommitted
begin try
	declare @returnValue int, @msgEroare varchar(500)
	if exists(select * from sysobjects where name='wIaNomenclatorPvSP1' and type='P')      
	begin
		exec @returnValue = wIaNomenclatorPvSP1 @sesiune=@sesiune,@parXML=@parXML output
		if @parXML is null
			return @returnValue 
	end

	declare @grupa varchar(13), @gestiune varchar(20), @gestutiliz varchar(20), @categoriePret int, 
			@cSub char(9), @utilizator varchar(20), @preturi int, 
			@nrElemente int, @start int, @linieNoua varchar(50)

	select	@grupa = isnull(@parXML.value('(/row/@grupa)[1]','varchar(80)'),''),
			@nrElemente = isnull(@parXML.value('(/row/@numarvizibil)[1]','int'), 999),
			@start = isnull(@parXML.value('(/row/@start)[1]','int'), 1),
			@linieNoua = @parXML.value('(/row/@linieNoua)[1]','varchar(50)')
	
	declare @arePoze int
	select @arePoze=1
	select @arePoze=(select val_logica from par where tip_parametru='PV' and parametru='TAREPOZA')
	
	if OBJECT_ID('tempdb..#n100') is not null
		drop table #n100
	if OBJECT_ID('tempdb..#stocpecod') is not null
		drop table #stocpecod
	
	------
	-- zona comentata pentru cand vom vrea sa tratam filtrarea sa afisam doar produsele pe stoc
	------
	
	--EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	
	--exec luare_date_par 'GE', 'SUBPRO', 0,0,@cSub output
	--exec luare_date_par 'GE', 'PRETURI', @Preturi output, 0, ''--setarea se lucreaza cu tabela de preturi

	--set @gestiune=''
	--set @gestutiliz=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod_proprietate='GESTIUNE' and cod=@utilizator),'')
	--if @gestutiliz <> '' 
	--	set @gestiune=@gestutiliz
	--set @categoriePret=isnull((select rtrim(valoare) from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestutiliz),'1')
	
	-- TODO: daca se foloseste, de tratat gestiuni atasate la GESTPV, nu lista gest ca propr.
	--declare @gestiuniUser table(gestiune varchar(13) primary key)
	--insert into @gestiuniUser
	--	select distinct RTRIM(valoare) 
	--	from proprietati p 
	--	where p.tip='UTILIZATOR' and p.cod_proprietate='GESTIUNE' and p.cod=@utilizator and p.Valoare<>''
	
	--select s.cod, sum(s.stoc) as stoc, sum(case when gFiltru.gestiune is null then 0 else s.stoc end) as stocpropriu
	--into #stocpecod
	--from stocuri s 
	--	inner join #n100 on s.cod=#n100.cod
	--	left outer join @gestiuniUser gFiltru on s.Cod_gestiune=gFiltru.gestiune
	--group by s.cod
	
	-- iau produsele de trimis
	declare @nomencl table (nr int, cod varchar(20), denumire varchar(200), um varchar(3), poza varchar(2000))
	
	insert @nomencl(nr, cod, denumire, um, poza)
	select top(@nrElemente) nr, 
			rtrim(n.cod), 
			convert(varchar(30), nr)+' '+rtrim(n.Denumire), 
			rtrim(n.UM),
			(case when @arePoze=1 then '/assets/img/product.png' else null end)
	from
		(select n.cod as cod, n.Denumire, n.um, 
				ROW_NUMBER() over(order by (isnull(pr.valoare,n.denumire))) nr
			from nomencl n
			left outer join proprietati pr on pr.tip='NOMENCL' and pr.cod_proprietate='GRORD' and pr.cod=n.cod and pr.valoare<>''
			where (@grupa='' or n.grupa = @grupa)
		) n
	where nr>=@start

	-- iau poza produselor
	update n
		set poza=pozeria.Fisier
	from @nomencl n, pozeRIA 
	where pozeria.Tip='N' and pozeria.cod=n.cod
	
	-- inserez produsele in forma xml
	insert into #articolePv(rownumber, xmlData)
		select nr, x.*
			from @nomencl n
			CROSS APPLY
			(
				SELECT 
					(
						SELECT *, @linieNoua linieNoua 
						FROM @nomencl nx
						WHERE n.nr = nx.nr
						FOR XML RAW
					) nx1
			)x
	
	--if OBJECT_ID('tempdb..#n100') is not null
	--	drop table #n100
	--if OBJECT_ID('tempdb..#stocpecod') is not null
	--	drop table #stocpecod
end try
begin catch
set @msgEroare=ERROR_MESSAGE()+'(wIaNomenclatorPv)'
raiserror(@msgEroare,11,1)
end catch	
