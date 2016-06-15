--***

create procedure [dbo].[wmNomenclator] @sesiune varchar(50),@parXML XML      
as      
if exists(select * from sysobjects where name='wmNomenclatorSP' and type='P')
begin
	exec wmNomenclatorSP @sesiune=@sesiune, @parXML=@parXML
	return 0
end

declare @FltStocPred int, @searchText varchar(80), @subunitate varchar(9), @tip varchar(2), @gestiune varchar(20),@gestutiliz varchar(20), @categoriePret int,
		@aplicatie varchar(100), @utilizator varchar(10), @codExact varchar(80), @discountMinim decimal(12,2), @discountMaxim decimal(12,2), @pasDiscount decimal(12,2),
		@discount decimal(12,2), @pretCuAmanuntul bit,@procDetalii varchar(255), @msgEroare varchar(4000), @prefiltrareGrupe bit, 
		/* salvez flag-uri ca si char pt. ca sa nu trimit in xml daca sunt null */@focusSearch char(1), @actiune varchar(50),
		@grupa varchar(20), @lista_gestiuni int,@tert varchar(20),@grupapenivele int,@contract varchar(20), @tipdetalii varchar(50), @meniuDetalii varchar(50),@dinAsistent int

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output 

	select	@searchText=(case when @codExact is not null then ''
			 else ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') end), 
			@subunitate=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), '1'), 
			@grupa=@parXML.value('(/row/@grupanom)[1]', 'varchar(50)'), 
			@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
			@aplicatie=ISNULL(@parXML.value('(/row/@aplicatie)[1]', 'varchar(2)'), ''), 
			@gestiune=ISNULL(@parXML.value('(/row/@gestiune)[1]', 'varchar(20)'), ''),
			@tert=@parXML.value('(/row/@tert)[1]', 'varchar(20)'), -- daca vreau sa afisez preturile atasate unui tert
			@discount=ISNULL(@parXML.value('(/row/@discount)[1]', 'decimal(12,2)'), 0), -- daca vreau sa sugerez un discount
			@contract=@parXML.value('(/row/@comanda)[1]', 'varchar(20)'), -- pentru culori si mici smecherii
			@procDetalii=isnull(@parXML.value('(/row/@wmNomenclator.procdetalii)[1]', 'varchar(50)'),''), -- procedura trimisa la frame pt. apelare dupa alegere.
			@tipdetalii=isnull(@parXML.value('(/row/@wmNomenclator.tipdetalii)[1]', 'varchar(50)'),'D'), -- pt. ca sa pot specifica tipul de macheta deschis la alegere produs.
			@meniuDetalii=isnull(@parXML.value('(/row/@wmNomenclator.meniuDetalii)[1]', 'varchar(50)'),'MD'), -- codul de meniu de unde sa ia form-ul deschis, implicit MD
			@dinAsistent=isnull(@parXML.value('(/row/@dinAsistent)[1]', 'int'),0) -- din asistent Vanzari
	
	select	@pretCuAmanuntul = (case when parametru='PRETAM' then Val_logica else @pretCuAmanuntul end), 
			@FltStocPred = (case when parametru='FSTOC' then Val_logica else @FltStocPred end),
			@prefiltrareGrupe = (case when parametru='GRNOM' then Val_logica else @prefiltrareGrupe end),
			@focusSearch = (case when parametru='FOCUSNOM' then convert(char,Val_logica) else @focusSearch end),
			@grupapenivele= (case when parametru='GRNIV' then convert(char,Val_logica) else @grupapenivele end)
	from par
	where Tip_parametru='AM' and Parametru in ('FSTOC', 'PRETAM', 'GRNOM', 'FOCUSNOM','GRNIV')


	if @focusSearch!='1'
		set @focusSearch=null
	
	
	if @aplicatie<>''
		set @tip=@aplicatie
		

	set @searchText=REPLACE(@searchText, ' ', '%')
	
	-- verific daca s-a scanat in searchText un cod de bare
	-- citesc iar atributul pt. ca variabila @searchText poate fi alterata.
	declare @codcitit varchar(100), @codScanat varchar(100)
	select	@codcitit=rtrim(@parXML.value('(/row/@searchText)[1]','varchar(100)')),
			@codcitit=REPLACE(@codcitit,'CipherLab','')

	if len(isnull(@codcitit,''))>0 -- vad daca e scris ceva in searchText
	begin
		--il cautam in tabela de coduri de bare
		select @codScanat=rtrim(cb.Cod_produs) from codbare cb where cb.Cod_de_bare=@codcitit
		
		/* cautare text din searchText in nomenclator
		dezactivat pt. ca adauga direct produse daca se scrie cod produs in searchText 
		daca se cauta cifra 1, si exista produs cu codul 1, deja sunt probleme
		if @codScanat is null
			select @codScanat=cod from nomencl where cod=@codcitit*/
		
		if @codScanat is not null --inseamna ca am gasit cod scanat
		begin
			-- fortez ca in lista sa fie un singur produs - nu e chiar optim, dar e solutia curenta.
			set @codExact=@codScanat 
			select @grupa = RTRIM(n.Grupa)
			from nomencl n where n.Cod=@codExact
			
			select @codScanat as codExact for xml raw('atribute'),root('Mesaje')
			set @actiune='autoSelect'
		end
	end
	
-- gestiuni atasate userului.
create table #gestiuni(gestiune varchar(50) primary key clustered)
insert #gestiuni(gestiune)
select RTRIM(valoare) from proprietati where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='GESTIUNE' and Valoare<>''
	
set @lista_gestiuni=(case when exists (select 1 from #gestiuni) then 1 else 0 end)
set @gestutiliz=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod_proprietate='GESTPV' and cod=@utilizator),'')
set @categoriePret=isnull((select max(valoare) from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestutiliz),'1')

	/* prefiltrare pe grupe de nomenclator */
if @prefiltrareGrupe=1 and (len(@searchText)<4)
begin
	select grupa
	into #grnivel1
	from grupe where isnull(grupa_parinte,'')=isnull(@grupa,'')

	declare @nrGrupeFii int,@nProdNom int
	set @nrGrupeFii=(select count(*) from grupe,#grnivel1 
		where #grnivel1.grupa=grupe.grupa_parinte)
	set @nProdNom=(select count(*) from nomencl,#grnivel1 where nomencl.grupa=#grnivel1.grupa)

	if (@grupa is null or @grupapenivele=1 and (@nrGrupeFii>0 or @nProdNom>0))
	begin
		declare @areGRORD int
		if exists(select 1 from proprietati pr where pr.tip='GRUPA' and pr.cod_proprietate='GRORD' and pr.valoare<>'')
			set @areGRORD=1
		else 
			set @areGRORD=0

		if @nrGrupeFii>0 --Grupe recursive 
		begin
			select top 100 rtrim(g.Grupa) cod, RTRIM(g.denumire) denumire, 'Grupe: '+ltrim(str(isnull(COUNT(distinct gfii.grupa),0))) info
			from grupe g
			left outer join grupe gfii on gfii.Grupa_parinte=g.grupa
			where 
			gfii.grupa is not null 
			and (g.grupa like @searchText+'%' or g.denumire like '%'+@searchText+'%')
			and isnull(g.grupa_parinte,'')=isnull(@grupa,'')
			group by g.grupa,g.denumire --ordonam dupa proprietatea GRORD din grupe, nu prea imi place proprietatea empty
			order by patindex('%'+@searchText+'%',g.denumire), g.denumire
			for xml raw
			
			set @nProdNom=0 --nu mai afisam pe grupe simple de mai jos
		end

		if @nProdNom>0 --Doar grupe
		begin
			select top 100 rtrim(g.Grupa) cod, RTRIM(g.denumire) as denumire, 'Articole: '+ltrim(str(isnull(COUNT(distinct nomencl.cod),0))) info
			from grupe g
			left outer join proprietati pr on pr.tip='GRUPA' and pr.cod_proprietate='GRORD' and pr.cod=g.grupa and pr.valoare<>''
			left outer join nomencl on g.Grupa=nomencl.grupa and nomencl.Tip<>'U'
			left join 
				(select cod, sum(stoc) stoc from stocuri where stocuri.Subunitate=@subunitate 
					and (@tip in ('PF','CI') and stocuri.Tip_gestiune='F' or @tip not in ('PF','CI') and stocuri.Tip_gestiune not in ('F', 'T'))
					and (@gestiune='' or stocuri.Cod_gestiune=@gestiune)
					and (@lista_gestiuni=0 or exists (select 1 from #gestiuni gu where gu.gestiune=stocuri.Cod_gestiune))
					group by cod) stocuri
				 on stocuri.Cod=nomencl.cod
			where
			(g.grupa like @searchText+'%' or g.denumire like '%'+@searchText+'%')
			and (@grupapenivele=0 or isnull(grupa_parinte,'')=isnull(@grupa,''))
			and (@areGRORD=0 or pr.valoare is not null)
			group by g.Grupa, g.denumire,ISNULL(pr.valoare,'99') --ordonam dupa proprietatea GRORD din grupe, nu prea imi place proprietatea empty
			having @FltStocPred=0 or abs(SUM(stocuri.stoc))>0.1
			order by ISNULL(pr.valoare,'99'), patindex('%'+@searchText+'%',g.denumire), g.denumire
			for xml raw
		end
		-- trimit numele procedurii apelante, pt. a fi citit din XML, si apelat cand se alege produsul.
		if len(@procDetalii)>0
			select @procDetalii as 'wmNomenclator.procdetalii', @tipdetalii as 'wmNomenclator.tipdetalii', @meniuDetalii as 'wmNomenclator.meniuDetalii' for xml raw('atribute'),root('Mesaje')
	
		select 'wmNomenclator' as detalii,1 as areSearch, '@grupanom' numeatr, @focusSearch as focusSearch,1 as _neimportant
		for xml raw,Root('Mesaje')
		return
	end
end --Gata selectul pt. GRUPE


-- citesc datele de numeric stepper pentru discount
exec wmIaDiscountAgent @sesiune=@sesiune, @discountMinim=@discountMinim output, @discountMaxim=@discountMaxim output, @pasDiscount=@pasDiscount output


	
create table #lastc (cod varchar(20),nrap int)
create unique clustered index cod on #lastc(cod)
if @tert is not null
begin
	declare @dLuna datetime
	set @dLuna=dateadd(month,-3,getdate())
	select top 1 @categoriePret=max(sold_ca_beneficiar),@discount=max(disccount_acordat) from terti where Subunitate=@subunitate and tert=@tert
	insert into #lastc
	select cod,count(*) as nrap
	from Contracte c
	JOIN PozContracte pc on c.idContract=pc.idContract and c.tip='CL' and c.tert=@tert and c.data>=@dLuna
	where @dinAsistent=0
	group by pc.cod

	if @contract is not null
	begin
		select cod 
		into #contractate
		from PozContracte where idContract=@contract
		group by cod

		delete #lastc 
		from #lastc,#contractate where #lastc.cod=#contractate.cod

		insert into #lastc
		select cod,-1
		from #contractate
	end

end

-- select produse din nomencl 
create table #coduri(cod varchar(20) primary key clustered, stoc float,nrap int) 
		
-- de testat pe bd cu multe produse - poate join-ul pe stocuri si top 25 se muta in select-ul de sub
insert #coduri(cod, stoc,nrap)
select top 25 rtrim(nomencl.cod), SUM(stocuri.stoc),isnull(#lastc.nrap,0)
from nomencl 
left join #lastc on nomencl.cod=#lastc.cod
left join stocuri on stocuri.Subunitate=@subunitate and stocuri.Tip_gestiune not in ('F', 'T')
		and stocuri.Cod=nomencl.cod and (@gestiune='' or stocuri.Cod_gestiune=@gestiune)
	and (@lista_gestiuni=0 or exists (select 1 from #gestiuni g where stocuri.Cod_gestiune=g.gestiune))
where nomencl.Cod=@codExact -- daca @codExact nu e null, aduc tot timpul o singura linie, cu acel cod.
	or -- lasati cu OR
		(@codExact is null 
		and (nomencl.denumire like '%'+@searchText+'%' or nomencl.cod like @searchText+'%') 
		and (@grupa is null or nomencl.Grupa=@grupa)
		and	nomencl.Tip<>'U')
group by isnull(#lastc.nrap,0),nomencl.cod, nomencl.denumire
having @codExact is not null or @FltStocPred=0 or abs(SUM(stocuri.stoc))>0.001
order by isnull(#lastc.nrap,0) desc,patindex('%'+@searchText+'%',nomencl.denumire), nomencl.denumire

--Se iau preturile din tabela de preturi cu wIaPreturi
create table #preturi(cod varchar(20),nestlevel int)
insert into #preturi
select cod,@@NESTLEVEL
from #coduri 

exec CreazaDiezPreturi

--trimit si punctul de livrare asa cum este asteptat in wiapreturi
set @parXMl=convert(xml,replace(CONVERT(varchar(max),@parXMl),'pctliv','punctlivrare'))
exec wIaPreturi @sesiune=@sesiune,@parXML=@parXML

select c.cod as cod, rtrim(max(nomencl.denumire)) as denumire,
	ltrim(CONVERT(varchar(20), sum(convert(decimal(15, 2), isnull(c.stoc, 0)))))+ ' ' + rtrim(max(nomencl.um))+','
	+ltrim(CONVERT(varchar(20), max(convert(decimal(15, 2), 
		isnull((case when @pretCuAmanuntul=1 then p.pret_amanunt_discountat else p.Pret_vanzare_discountat end),0)))))+' lei, Cod: '+rtrim(max(nomencl.cod)) as info,--/ '+rtrim(max(nomencl.um))  as info,  
		
	max(convert(decimal(15, 2), isnull((case when @pretCuAmanuntul=1 then p.pret_amanunt else p.Pret_vanzare end),0))) as pret,
	1 as cantitate,
	(case when c.nrap=-1 then '0xd3d3d3' when c.nrap>0 then '0x00ff00' when isnull(pz.fisier,'')<>'' then '0x000040' else '0xffffff' end) as culoare
	--, @discountMinim as discountmin, @discountMaxim as discountmax, @pasDiscount as discountpas, @discount as discount
from nomencl
	inner join #coduri c on nomencl.Cod=c.cod
	left outer join #preturi p on nomencl.cod=p.cod
	left outer join pozeria pz on c.cod=pz.cod and pz.tip='N'
group by c.cod,nomencl.Denumire,nomencl.tip,c.nrap, pz.fisier
order by c.nrap desc,patindex('%'+@searchText+'%',nomencl.denumire),2
for xml raw 
		
if len(@procDetalii)=0 --Probabil e apelat din meniu
	select 'wmDetStocuri' procdetalii, 1 areSearch, @actiune as actiune,
		(case when @codScanat is not null then 1 else null end) as clearSearch, @focusSearch as focusSearch,
		'@cod' numeatr
	for xml raw,Root('Mesaje')
else
	select @procDetalii as detalii,1 as areSearch, 'Alege produs' as titlu,
		@tipdetalii as tipdetalii, @actiune as actiune, '@cod' numeatr,
		(case when @codScanat is not null then 1 else null end) as clearSearch, @focusSearch as focusSearch,
		dbo.f_wmIaForm(@meniuDetalii) as 'form'
	for xml raw,Root('Mesaje')
end try
begin catch
		set @msgEroare=ERROR_MESSAGE()+'(wmNomenclator)'
end catch

begin try 
	if OBJECT_ID('#coduri') is not null
		drop table #coduri
	if OBJECT_ID('#gestiuni') is not null
		drop table #gestiuni
end try
begin catch end catch

if (1 = @@NESTLEVEL)
	select '@searchText,@tert,@grupanom' as atribute,1 as '@_neimportant' for xml raw('atributeRelevante'),root('Mesaje')

if @msgEroare is not null
	raiserror(@msgEroare,11,1)
	
