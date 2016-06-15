--***
create procedure rapOfertadeProduse (@sesiune varchar(50)=null,
		@cod varchar(20)=null, @grupa varchar(20)=null, @gestiunea varchar(20)=null,
		@furnizor varchar(20)=null,
		@pestoc bit=0,	-- 0=toate, 1=doar cele pe stoc
		@ordonare int=0,	-- 0=cod, 1=denumire
		@categoria varchar(20)=null,	-- categoria pret (preturi.UM)
		@locatie varchar(200)=null
		)
as
begin
	if OBJECT_ID('tempdb..#pretIntrare')>0 drop table #pretIntrare
	if OBJECT_ID('tempdb..#nomencl')>0 drop table #nomencl
	if OBJECT_ID('tempdb..#preturi')>0 drop table #preturi

	declare @fltCod bit, @fltGrupa bit, @fltGestiune bit, @fltFurnizor bit, @fltCategoria bit
	select @fltCod=(case when @cod is null then 0 else 1 end),
		@fltgrupa=(case when @grupa is null then 0 else 1 end),
		@fltGestiune=(case when @gestiunea is null then 0 else 1 end),
		@fltFurnizor=(case when @furnizor is null then 0 else 1 end),
		@fltCategoria=(case when @categoria is null then 0 else 1 end)
		--/*
	select cod, denumire, UM into #nomencl from nomencl n where (@fltCod=0 or cod=@cod) and
		 (@fltGrupa=0 or Grupa=@Grupa) and (@fltGestiune=0 or n.Gestiune=@gestiunea)
		 and (@fltFurnizor=0 or n.Furnizor=@furnizor)
	create index ncod on #nomencl(cod)--*/
	select s.cod, row_number() over (partition by s.cod order by s.data desc) rand, s.pret pret_stoc, stoc,		--> cu "rand" se identifica ultima linie cu stoc
			row_number() over (partition by s.cod, (case when s.pret<>0 then 1 else 0 end) order by s.data desc) as randcupret	--> cu "randcupret" se identifica ultima linie cu pret de stoc<>0
	into #pretintrare
		from stocuri s inner join #nomencl n on s.Cod=n.Cod
		where (@fltCod=0 or s.cod=@cod)
			and s.Tip_gestiune<>'A'
			and (@locatie is null or s.locatie=@locatie)
			and not exists (select 1 from pozdoc p where s.idintrare=p.idpozdoc and p.tip in ('TE','AP'))	--> preturile de pe transferuri incurca

	create index printrare on #pretintrare(cod)
	update p set p.stoc=pr.stoc from #pretintrare p
		inner join (select sum(stoc) stoc, p.Cod from #pretintrare p group by p.Cod) pr
			on p.Cod=pr.cod and p.rand=1
	delete p from #pretintrare p where (p.rand>1 or (@pestoc=0 or p.stoc<=0)) and (p.randcupret>1 or pret_stoc=0)	--> elimin liniile neinteresante (care nu contin nici pretul de stoc si nici stocul curent)
/*
	select pret_vanzare, pret_cu_amanuntul, p.Cod_produs,
		row_number() over (partition by p.cod_produs order by data_superioara desc, data_inferioara desc) as rand	--> se identifica ultimul pret cu amanuntul si ultimul pret vanzare
	into #preturi from preturi p inner join #nomencl n on n.Cod=p.Cod_produs
		and p.Data_superioara>='2999-1-1'
		and (@fltCategoria=0 or p.um=@categoria)
*/
	create table #preturi(cod varchar(20),nestlevel int)
	insert into #preturi
	select n.cod,@@NESTLEVEL
	from #nomencl n
		
	exec CreazaDiezPreturi
	declare @px xml
	select @px=(select @categoria as categoriePret, getdate() as data, @gestiunea as gestiune for xml raw)
	exec wIaPreturi @sesiune=null,@parXML=@px

	select rtrim(n.Cod) cod, rtrim(n.Denumire) denumire, rtrim(n.UM) um,
		p.Pret_vanzare pret_vanzare, p.Pret_amanunt pret_cu_amanuntul,
		pr1.pret_stoc as pret_stoc,
		(case when isnull(pr1.pret_stoc,0)=0 then 100 
			else 100*(p.pret_vanzare-isnull(pr1.pret_stoc,0))/isnull(pr1.pret_stoc,0)
			end) procent_adaos
	from #nomencl n left join #preturi p on n.Cod=p.Cod
		left join #pretIntrare pr on pr.Cod=n.Cod and pr.rand=1				--> din "pr" se ia stocul
		left join #pretIntrare pr1 on pr1.Cod=n.Cod and pr1.randcupret=1	--> din "pr1" se ia ultimul pret de stoc diferit de 0
	where (@pestoc=0 or pr.cod is not null)
		and (@locatie is null or pr.cod is not null)
	order by (case when @ordonare=0 then n.Cod else n.denumire end)
	
	if OBJECT_ID('tempdb..#pretIntrare')>0 drop table #pretIntrare
	if OBJECT_ID('tempdb..#nomencl')>0 drop table #nomencl
	if OBJECT_ID('tempdb..#preturi')>0 drop table #preturi
end
