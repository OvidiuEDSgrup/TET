create procedure rapSituatiiPeCentre(@DataJos datetime,@DataSus datetime
		,@grupare varchar(1)	--> 1=locm, 2=comenzi, 3=unitate, 4=centre asociate
		,@chelt_ven varchar(1)	--> 0=Ambele, 1=cheltuieli, 2=venituri
		,@condens int			--> nivel de condensare
		,@lm varchar(20)=null,@comanda varchar(40)=null,@cont varchar(40)=null	--> filtre
	--- ascunse:
		,@grup_com bit	-->	1=Da
		,@tipX varchar(1)=0	-->	Si cheltuieli pe comenzi tip X furnizoare: 0=Nu, 1=Da
		,@strict int=0
		,@tip_com varchar(1)=null	--> null=toate	--> P=Productie terti	-->	R=Servicii terti
			--> X=Auxiliara	--> T=Transport	--> C = Productie auxiliara	--> S = Semifabricat	--> V = Servicii auxiliare
			--> L = Regie sectie	--> G = Regie generala
		,@exceptie varchar(40)=null,@jurnal varchar(40)=null,@comanda_completata varchar(1)=null
		,@tert varchar(40)=null)

as
/*	--	apel pt teste:
declare @grupare nvarchar(1),@DataJos datetime,@DataSus datetime,@lm nvarchar(7),@comanda nvarchar(4000),@grup_com bit,@cont nvarchar(4000),@chelt_ven nvarchar(1),@tert nvarchar(4000),@tip_com nvarchar(4000),@exceptie nvarchar(4000),@jurnal nvarchar(4000),@comanda_completata nvarchar(1),@tipX nvarchar(1),@strict int,@condens int
select @grupare=N'1',@DataJos='2012-01-01 00:00:00',@DataSus='2012-02-01 00:00:00',@lm=N'asdsawe',@comanda=NULL,@grup_com=0,@cont=NULL,@chelt_ven=N'0',@tert=NULL,@tip_com=NULL,@exceptie=NULL,@jurnal=NULL,@comanda_completata=N'0',@tipX=N'0',@strict=0,@condens=3

exec rapSituatiiPeCentre @grupare=@grupare,@DataJos=@DataJos,@DataSus=@DataSus,@lm=@lm,@comanda=@comanda
	,@grup_com=@grup_com, @cont=@cont,@chelt_ven=@chelt_ven,@tert=@tert,@tip_com=@tip_com
	,@exceptie=@exceptie,@jurnal=@jurnal,@comanda_completata=@comanda_completata,@tipX=@tipX
	,@strict=@strict,@condens=@condens
*/
--exec fainregistraricontabile @datasus=@DataSus
set transaction isolation level read uncommitted
declare @q_condens int
		,@q_grupare int, @q_comanda_completata bit, @q_chelt_ven int,@q_tipX bit,
		@q_grup_com varchar(100),
		@q_cont varchar(100),@q_lm varchar(100), @q_tip_com varchar(100), @q_comanda varchar(100), @q_tert varchar(100), @q_exceptie varchar(100), 
		@q_jurnal varchar(100),@q_strict bit,
		@q_DataJos datetime,@q_DataSus datetime
		,@nrmaxdetalii int
set @condens=isnull(@condens,(select top 1 lungime from strlm order by nivel))
select @q_condens=(case when @condens is not null 
						then (select top 1 lungime from strlm where nivel<=@condens order by nivel desc) else null end)
	,@q_grupare=@grupare, @q_comanda_completata=@comanda_completata, @q_chelt_ven=@chelt_ven
	,@q_tipX=@tipX, @q_grup_com=@grup_com, @q_cont=@cont, @q_lm=@lm, @q_tip_com=@tip_com
	,@q_comanda=@comanda, @q_tert=@tert, @q_exceptie=@exceptie, @q_jurnal=isnull(@jurnal,'')
	,@q_strict=@strict, @q_DataJos=@DataJos, @q_DataSus=@DataSus	--*/
	,@nrmaxdetalii=100000
	
	if object_id('temdb.dbo.#final') is not null drop table #final
	if object_id('temdb.dbo.#ptantet') is not null drop table #ptantet
	if object_id('temdb.dbo.#tmp') is not null drop table #tmp
	if object_id('temdb.dbo.#lm') is not null drop table #lm

	select max(Nivel) nivel, rtrim(lm.cod) as Cod, max(Cod_parinte) cod_parinte, max(Denumire) denumire, max(s.marca) marca,
		max(rtrim(case when len(isnull(s.comanda,''))>20 then substring(isnull(s.comanda,''),21,len(isnull(s.comanda,''))-20) else '' end)) as denumire_centru_cost
	into #lm from lm left join speciflm s on lm.cod=s.loc_de_munca
	where lm.cod like @q_lm+'%'	or @q_lm is null
	group by lm.cod
--	*/
	
if (@q_grupare=5)	-- tratez cazul "Pe centre asociate"
begin
	update #lm set marca=l.marca from #lm,#lm l where rtrim(l.marca)<>'' and #lm.cod like rtrim(l.cod)+'%'
	insert into #lm(Nivel, Cod, Cod_parinte, Denumire, marca) select 0,marca,'', '', marca from #lm group by marca
end
if (@q_grupare=5)	-- tratez cazul "Pe centre asociate"
		update #lm set cod_parinte=marca
	create unique clustered index ind_lm on #lm(cod,nivel)
	--filtrare pe locurile de munca configurate pe utilizatori
declare @utilizator varchar(20), @eLmUtiliz int
declare @LmUtiliz table(valoare varchar(200))
select @utilizator=dbo.fIaUtilizator('')
insert into @LmUtiliz(valoare)
select --* from fPropUtiliz() where valoare<>'' and cod_proprietate='LOCMUNCA'
	cod from lmfiltrare where utilizator=@utilizator
set @eLmUtiliz=isnull((select max(1) from @LmUtiliz),0)

create table #tmp
	(
	cod varchar(40), tip_document varchar(2), numar_document varchar(20), data datetime
	,cont_debitor varchar(40), cont_creditor varchar(40), sgn decimal(1), suma decimal(20,3)
	,explicatii varchar(100), lm_den varchar(100), nume_com varchar(100), nume_cont_deb varchar(100)
	,nume_cont_cred varchar(100), cod_centru_de_cost varchar(20), denumire_centru_cost varchar(100)
	,locm varchar(20), contul varchar(40), inceput_de_cont varchar(40), sursa varchar(1)
	,loc_de_munca varchar(20), comanda varchar(40), com varchar(40), Subunitate varchar(20)
	, descriere varchar(100), den_lm varchar(100),
	-- urmatoarele campuri sunt pentru update ulterior, pt renuntare la tabela intermediara #detalii
	cod_parinte varchar(100) default '', den_conden varchar(100) default '',
	cod_condens varchar(100) default '', cod_grupare varchar(100) default '', condensat int default 0
	)
	
insert into #tmp(
		cod, tip_document, numar_document, data, cont_debitor, cont_creditor, sgn, suma, explicatii
		,lm_den, nume_com, nume_cont_deb, nume_cont_cred, cod_centru_de_cost, denumire_centru_cost
		,locm, contul, inceput_de_cont, sursa, loc_de_munca, comanda, com, Subunitate
		, descriere, den_lm
	)
select (case @q_grupare	when 1 then rtrim(a.loc_de_munca)
					when 2 then rtrim(left(a.comanda,20))	
					when 3 then 'Pe unitate'
					when 4 then ''
					when 5 then isnull(rtrim(l.marca),'')	--'lm.marca' --rtrim(lm.marca)
					else '' end
	) as cod,a.tip_document, a.numar_document, a.data, rtrim(a.cont_debitor), rtrim(a.cont_creditor), 
		-(case when left(a.cont_debitor,1)='6' or left(a.cont_debitor,1)='7' then 1 else -1 end) as sgn,
		a.suma, a.explicatii,
		--	</SPACE(100) 
		l.denumire as lm_den,
		(case when @q_grupare<>3 then c.descriere else '' end) as nume_com,
		con1.denumire_cont as nume_cont_deb,
		con2.denumire_cont as nume_cont_cred,
		isnull(rtrim(l.marca),'') as cod_centru_de_cost,
		isnull(l.denumire_centru_cost,'') denumire_centru_cost,
			--/>
(case when @q_grupare<>2 then
		(case when left(a.cont_debitor,1)='6' or left(a.cont_debitor,1)='7' then a.cont_debitor
		when left(a.cont_creditor,1)='6' or left(a.cont_creditor,1)='7' then a.cont_creditor else '' end) end)
		as locm,	--> Luci: ce o fi asta? locm sau cont?
rtrim(case when left(a.cont_debitor,1)='6' or left(a.cont_debitor,1)='7' then a.cont_debitor when left(a.cont_creditor,1)='6' 
		or left(a.cont_creditor,1)='7' then a.cont_creditor else '' end) as contul, 
(case when left(a.cont_debitor,1)='6'
		or left(a.cont_debitor,1)='7' then left(a.cont_debitor,1) when left(a.cont_creditor,1)='6' 
		or left(a.cont_creditor,1)='7' then left(a.cont_creditor,1) else '' end) as inceput_de_cont,
		' ' as sursa, a.loc_de_munca, rtrim(left(a.comanda,20))as comanda, (case when @q_grupare<>3 then left(a.comanda,20) else '' end) as com
		,a.Subunitate ,(case when @q_grupare=2 then c.descriere else null end) descriere, l.denumire as den_lm
from pozincon a
	left join comenzi c on c.comanda=left(a.comanda,20)
	left join #lm l on a.loc_de_munca=l.Cod
	left join conturi con1 on con1.subunitate=a.subunitate and con1.cont=cont_debitor
	left join conturi con2 on con2.subunitate=a.subunitate and con2.cont=cont_creditor
where	-- conditii:
	a.subunitate=(select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO')
	and (left(a.cont_debitor,1)='6' or left(a.cont_debitor,1)='7' or left(a.cont_creditor,1)='6' or left(a.cont_creditor,1)='7') 
	and (left(a.cont_debitor,3)<>'121' and left(a.cont_creditor,3)<>'121')
	-- filtre:
	and a.data between @q_DataJos and @q_DataSus	
	and (left(a.loc_de_munca,(case when @q_strict = 1 then 20 else len(rtrim(isnull(@q_lm,''))) end))=rtrim(isnull(@q_lm,'')))
	and (@q_comanda is null or @q_comanda is not null and @q_grup_com=0 and 
			c.comanda=@q_comanda or @q_comanda is not null and @q_grup_com=1
		and c.comanda like rtrim(@q_comanda)+'%')
	and (@q_cont is null or a.cont_debitor like rtrim(@q_cont)+'%' or a.cont_creditor like rtrim(@q_cont)+'%') 
	and (@q_chelt_ven=0 or (@q_chelt_ven=1 and (left (a.cont_debitor,1)='6' or left (a.cont_creditor,1)='6')) or 
						 (@q_chelt_ven=2 and (left (a.cont_debitor,1)='7' or left (a.cont_creditor,1)='7'))) 
	and (@q_tert is null or c.beneficiar=@q_tert)
	and (@q_tip_com is null or c.tip_comanda=@q_tip_com)
	and (@q_exceptie is null or (a.cont_debitor not like rtrim(@q_exceptie)+'%' and a.cont_creditor not like 
									rtrim(@q_exceptie)+'%'))
--	and (@q_jurnal is null or a.jurnal like rtrim(@q_jurnal)+'%')
	and (@q_comanda_completata=0 or isnull(c.comanda,'')<>'')
	and (@eLmUtiliz=0 or exists (select 1 from @LmUtiliz u where u.valoare=a.Loc_de_munca))
	order by locm,(case when left(a.cont_debitor,1)='6'
			or left(a.cont_debitor,1)='7' then left(a.cont_debitor,1) when left(a.cont_creditor,1)='6' 
			or left(a.cont_creditor,1)='7' then left(a.cont_creditor,1) else '' end),com, sursa, contul, a.data, a.tip_document
			, rtrim(numar_document), suma
	--/*
	--> (Luci:) Urmatorul update rectifica inversarea conturilor daca apare, de exemplu, contul de clasa 7 ca fiind corespondent si suma este negativa:
	update t set cont_debitor=cont_creditor, cont_creditor=cont_debitor, sgn=-sgn--, suma=-suma
		,contul=(case when contul=cont_creditor then cont_debitor else cont_creditor end)
		--,inceput_de_cont=(case when inceput_de_cont=left(cont_creditor,1) then left(cont_debitor,1) else left(cont_creditor,1) end)
		,nume_cont_cred=nume_cont_deb, nume_cont_deb=nume_cont_cred
	from #tmp t where left(t.cont_creditor,1) in ('7','6') and left(t.cont_debitor,1) not in ('7','6') and t.sgn<0
	--> (Luci:) Adaug insersele notelor contabile de la clasa 7 la 7 si 6 la 6 pentru a nu fi alterate totalurile:
	insert into #tmp(cod, tip_document, numar_document, data, cont_debitor, cont_creditor, sgn, suma, explicatii
		,lm_den, nume_com, nume_cont_deb, nume_cont_cred, cod_centru_de_cost, denumire_centru_cost
		,locm, contul, inceput_de_cont, sursa, loc_de_munca, comanda, com, Subunitate
		, descriere, den_lm)
	select cod, tip_document, numar_document, data, cont_creditor, cont_debitor, -sgn, suma, explicatii
		,lm_den, nume_com, nume_cont_cred, nume_cont_deb, cod_centru_de_cost, denumire_centru_cost
		,locm, 
		(case when contul=cont_creditor then cont_debitor else cont_creditor end) as contul , 
		--(case when inceput_de_cont=left(cont_creditor,1) then left(cont_debitor,1) else left(cont_creditor,1) end) 
		inceput_de_cont
		,sursa, loc_de_munca, comanda, com, Subunitate
		, descriere, den_lm
	from #tmp t where left(t.cont_debitor,1)='7' and left(t.cont_creditor,1)='7' or left(t.cont_debitor,1)='6' and left(t.cont_creditor,1)='6'
		--*/
--if suser_name()='CLUJ\luci.maier' and app_name() not like '%.net%' select 'test', * from #tmp 
	update t set cod=left(rtrim(t.cod),@q_condens), cod_parinte=(case when (@q_grupare=1 or @q_grupare=5) then rtrim(left(t.loc_de_munca,@q_condens)) else null end)
		, den_conden=(case @q_grupare when 2 then descriere when 3 then 'Pe unitate' when 5 then t.denumire_centru_cost else (case when (@q_grupare=1 or @q_grupare=5) then t.den_lm else null end) end)
		, cod_condens=left(t.cod,(case when len(t.cod)>isnull(@q_condens,10) then isnull(@q_condens,10) else len(t.cod) end))
		, cod_grupare=rtrim(case @q_grupare when 1 then left(t.cod,@q_condens) when 2 then rtrim(t.comanda) when 3 then '' else left(t.cod,@q_condens) end)
		from #tmp t

declare @sufix varchar(1) -- pentru a grupa datele pt locuri de munca necondensate dar cu date operate
set @sufix=(case when @q_grupare=1 then '.' else '' end)
	--create index ind_tmp on #tmp(cod_grupare)
create table #ptantet(cod varchar(40), cod_parinte varchar(100), den_conden varchar(100), tip_document varchar(2)
		, numar_document varchar(20), data datetime, cont_debitor varchar(40), cont_creditor varchar(40), sgn decimal(1)
		, suma decimal(20, 3), explicatii varchar(100), lm_den varchar(100), nume_com varchar(100), nume_cont_deb varchar(100)
		, nume_cont_cred varchar(100), cod_centru_de_cost varchar(20), denumire_centru_cost varchar(100)
		, locm varchar(20), contul varchar(40), inceput_de_cont varchar(40), sursa varchar(1)
		, loc_de_munca varchar(20), comanda varchar(40), com varchar(40)
		, cod_condens varchar(100), condensat int, cod_grupare varchar(100)
	)	--> #ptantet = tabela intermediara pt totalizari partiale pentru grupari - pt optimizare 
insert into #ptantet(cod, cod_parinte, den_conden, tip_document, numar_document, data, cont_debitor, cont_creditor, sgn, suma, explicatii, lm_den, 
		nume_com, nume_cont_deb, nume_cont_cred, cod_centru_de_cost, denumire_centru_cost, locm, contul, inceput_de_cont, sursa, loc_de_munca, 
		comanda, com, cod_condens, condensat, cod_grupare)
	select cod, cod_parinte, max(den_conden), max(tip_document), max(numar_document), max(data)
		, max(cont_debitor), max(cont_creditor), max(sgn)
		, sum(sgn*suma), max(explicatii), max(lm_den)
		, max(nume_com), max(nume_cont_deb), max(nume_cont_cred), max(cod_centru_de_cost), max(denumire_centru_cost), max(locm)
		, contul, inceput_de_cont, max(sursa), max(loc_de_munca)
		, max(comanda), max(com), max(cod_condens), max(condensat), cod_grupare
	from #tmp
	group by cod_grupare, cod, inceput_de_cont, contul, cod_parinte
	--> organizarea finala a datelor:
create table #final(cod varchar(40), cod_parinte varchar(100), den_conden varchar(100), tip_document varchar(2)
		, numar_document varchar(20), data datetime, cont_debitor varchar(40), cont_creditor varchar(40), sgn decimal(1)
		, suma decimal(20, 3), explicatii varchar(100), lm_den varchar(100), nume_com varchar(100), nume_cont_deb varchar(100)
		, nume_cont_cred varchar(100), cod_centru_de_cost varchar(20), denumire_centru_cost varchar(100)
		, locm varchar(20), contul varchar(40), inceput_de_cont varchar(40), sursa varchar(1)
		, loc_de_munca varchar(20), comanda varchar(40), com varchar(40)
		, cod_condens varchar(100), condensat int
	)

if (@q_grupare=1 or @q_grupare=3 or @q_grupare=5)				-- pe unitate / completare pt varianta pe loc de munca
	insert into #final(cod, cod_parinte, den_conden, tip_document, numar_document, data, cont_debitor, cont_creditor, sgn, suma, explicatii, lm_den, 
		nume_com, nume_cont_deb, nume_cont_cred, cod_centru_de_cost, denumire_centru_cost, locm, contul, inceput_de_cont, sursa, loc_de_munca, 
		comanda, com, cod_condens, condensat)
	select cod_grupare+@sufix
		 as cod, 
		cod_grupare as cod_parinte, max(case when len(l.cod)<=@q_condens then l.denumire else 'Unitate' end) as den_conden,
		max(tip_document), max(numar_document), max(data), max(cont_debitor), max(cont_creditor), max(sgn), 0 as suma, max(explicatii), max(lm_den), 
		max(nume_com), max(nume_cont_deb), max(nume_cont_cred), max(cod_centru_de_cost), max(l.denumire_centru_cost), max(locm), max(contul), 
		max(inceput_de_cont), max(sursa), 
		max(loc_de_munca), max(comanda), max(com), max(cod_condens),0 as condensat
	from #ptantet d left join #lm l on l.cod=d.cod_parinte
		where @q_grupare=1 or @q_grupare=3 or @q_grupare=5 and len(cod_grupare)<@q_condens
		group by cod_grupare
		
if (@q_grupare=2)												-- pe comenzi
	insert into #final(cod, cod_parinte, den_conden, tip_document, numar_document, data, cont_debitor, cont_creditor, sgn, suma, explicatii, lm_den, 
		nume_com, nume_cont_deb, nume_cont_cred, cod_centru_de_cost, denumire_centru_cost, locm, contul, inceput_de_cont, sursa, loc_de_munca, 
		comanda, com, cod_condens, condensat)
	select cod_grupare as cod, '' as cod_parinte, max(den_conden) as den_conden,
		max(tip_document), max(numar_document), max(data), max(cont_debitor), max(cont_creditor), max(sgn), 0 as suma, max(explicatii), max(lm_den), 
		max(nume_com), max(nume_cont_deb), max(nume_cont_cred), max(cod_centru_de_cost), max(d.denumire_centru_cost), max(locm), max(contul), 
		max(inceput_de_cont), max(sursa), 
		max(loc_de_munca), max(comanda), max(com), max(cod_condens),0 as condensat
	from #ptantet d
		group by cod_grupare

if (@q_grupare=1 or @q_grupare=5)								-- pe loc de munca / centre asociate
	insert into #final(cod, cod_parinte, den_conden, tip_document, numar_document, data, cont_debitor, cont_creditor, sgn, suma, explicatii, lm_den, 
		nume_com, nume_cont_deb, nume_cont_cred, cod_centru_de_cost, denumire_centru_cost, locm, contul, inceput_de_cont, sursa, loc_de_munca, 
		comanda, com, cod_condens, condensat)
	select 
		rtrim(left(l.cod,@q_condens)) as cod, min(rtrim(l.cod_parinte)) as cod_parinte, max(case when len(l.cod)<=@q_condens then l.denumire else '' end) as den_conden,
		max(tip_document), max(numar_document), max(data), 
		'' as cont_debitor, max(cont_creditor), max(sgn), 0 as suma, max(explicatii), max(lm_den), 
		max(nume_com), max(nume_cont_deb), max(nume_cont_cred), max(cod_centru_de_cost), max(l.denumire_centru_cost), max(locm), max(contul), 
		max(inceput_de_cont), max(sursa), 
		max(loc_de_munca), max(comanda), max(com), max(cod_condens),0 as condensat
	from #lm l left join #ptantet d on l.cod=d.cod_parinte
		where exists (select 1 from #tmp dd where dd.loc_de_munca like l.cod+'%')
		group by rtrim(left(l.cod,@q_condens))

insert into #final(cod, cod_parinte, den_conden, tip_document, numar_document, data, cont_debitor, cont_creditor, sgn, suma, explicatii, lm_den, 
		nume_com, nume_cont_deb, nume_cont_cred, cod_centru_de_cost, denumire_centru_cost, locm, contul, inceput_de_cont, sursa, loc_de_munca, 
		comanda, com, cod_condens, condensat)
	select 
	d.cod_grupare
	+'z'+rtrim(d.inceput_de_cont),
	max(d.cod_grupare+@sufix
	) 
	as cod_parinte, max(d.den_conden) as den_conden,
	max(tip_document), max(numar_document), max(data), max(cont_debitor), max(cont_creditor), max(sgn), 0 as suma, max(explicatii), max(lm_den), 
	max(nume_com), max(nume_cont_deb), max(nume_cont_cred), max(cod_centru_de_cost), max(d.denumire_centru_cost), max(locm), max(contul), 
	max(inceput_de_cont), max(sursa), 
	max(loc_de_munca), max(comanda), max(com), max(cod_condens),1 as condensat	
from #ptantet d
	where len(d.cod)<=@q_condens
	group by d.cod_grupare+'z'+rtrim(d.inceput_de_cont)			-- gruparea cheltuieli / venituri
	union all	
select 
	d.cod_grupare+'z'+rtrim(d.inceput_de_cont)+'z'+rtrim(d.contul), 
	max(d.cod_grupare+'z'+rtrim(d.inceput_de_cont)) as cod_parinte, max(d.den_conden) as den_conden,
	max(tip_document), max(numar_document), max(data), max(cont_debitor), max(cont_creditor), max(sgn), 0 as suma, max(explicatii), max(lm_den), 
	max(nume_com), max(nume_cont_deb), max(nume_cont_cred), max(cod_centru_de_cost), max(d.denumire_centru_cost), max(locm), max(contul), 
	max(inceput_de_cont), max(sursa), 
	max(loc_de_munca), max(comanda), max(com), max(cod_condens),2 as condensat
from #ptantet d
	where len(d.cod)<=@q_condens
	group by d.cod_grupare+'z'+rtrim(d.inceput_de_cont)+'z'+rtrim(d.contul)		-- gruparea pe conturi

if (select count(1) from #tmp)<@nrmaxdetalii -- daca datele sunt prea multe raportul va fi centralizat:
insert into #final(cod, cod_parinte, den_conden, tip_document, numar_document, data, cont_debitor, cont_creditor, sgn, suma, explicatii, lm_den, 
		nume_com, nume_cont_deb, nume_cont_cred, cod_centru_de_cost, denumire_centru_cost, locm, contul, inceput_de_cont, sursa, loc_de_munca, 
		comanda, com, cod_condens, condensat)
select 
	rtrim(d.cod_grupare)+'z'+rtrim(d.inceput_de_cont)+'z'+rtrim(d.contul)+'z'+rtrim(convert(varchar(10),row_number() over (order by numar_document))), 
	rtrim(d.cod_grupare)+'z'+rtrim(d.inceput_de_cont)+'z'+rtrim(d.contul) as cod_parinte, den_conden, tip_document, numar_document, data, cont_debitor, cont_creditor, sgn, suma, explicatii, lm_den, 
	nume_com, nume_cont_deb, nume_cont_cred, cod_centru_de_cost, d.denumire_centru_cost, locm, contul, inceput_de_cont, sursa, 
	loc_de_munca, comanda, com, cod_condens,3 as condensat
from #tmp d
	where len(d.cod)<=@q_condens												-- detaliile
else
	insert into #final(cod, cod_parinte, den_conden, tip_document, numar_document, data, cont_debitor, cont_creditor, sgn, suma, explicatii, lm_den, 
		nume_com, nume_cont_deb, nume_cont_cred, cod_centru_de_cost, denumire_centru_cost, locm, contul, inceput_de_cont, sursa, loc_de_munca, 
		comanda, com, cod_condens, condensat)
select 
	rtrim(d.cod_grupare)+'z'+rtrim(d.inceput_de_cont)+'z'+rtrim(d.contul)+'z'+rtrim(convert(varchar(10),row_number() over (order by numar_document))), 
	rtrim(d.cod_grupare)+'z'+rtrim(d.inceput_de_cont)+'z'+rtrim(d.contul) as cod_parinte, den_conden, '' tip_document, 'nedetaliat' numar_document, data, cont_debitor, cont_creditor, 
	1 sgn, suma, 'prea multe date' explicatii, lm_den, 
	nume_com, nume_cont_deb, nume_cont_cred, cod_centru_de_cost, d.denumire_centru_cost, locm, contul, inceput_de_cont, sursa, 
	loc_de_munca, comanda, com, cod_condens,3 as condensat
from #ptantet d
	where len(d.cod)<=@q_condens												-- detaliile pt varianta centralizat

	delete from #final where tip_document is null and not exists (select 1 from #final f where f.cod like #final.cod)
	delete from #final where (select COUNT(1) from #final f where condensat=0 and f.cod like rtrim(#final.cod_parinte)+'%')=2 and rtrim(#final.cod) like '%.' --and #final.condensat<=1--exclud acele randuri cu sufix care sunt in plus
	update #final set cod_parinte=REPLACE(cod_parinte,'.','') where rtrim(cod_parinte) like '%.' and not exists (select 1 from #final f where f.cod=#final.cod_parinte) --corectez parintii randurilor sterse

	update #final set cont_debitor=(select COUNT(1) from #final f where condensat=0 and f.cod like rtrim(#final.cod)+'%' or cod='')
	where condensat=0 --aici aflu cate noduri tip loc de munca sunt in subarborele al carei radacina este linia curenta; pentru afisarea corecta a toggle-urilor

--order by condensat*/--*/
--/*

select (case condensat 
			when 0 then --> conditie in functie de parametru tip=pe ce se grupeaza ?!?
							replace(cod,'.','')+left(rtrim(den_conden),25)
						when 1 then case when inceput_de_cont='6' then 'Cheltuieli' else 'Venituri' end
						when 2 then contul+'-    '+left((case when contul=cont_creditor then nume_cont_cred else nume_cont_deb end),30)
						when 3 then convert(varchar(20),data,103)+' '+tip_document+' '+numar_document
			end)	denumire_grupare
		,cod, cod_parinte, den_conden, tip_document, numar_document, data, cont_debitor, cont_creditor, 
		sgn, suma, explicatii, lm_den, nume_com, nume_cont_deb, nume_cont_cred, cod_centru_de_cost, 
		denumire_centru_cost, locm, contul, inceput_de_cont, sursa, loc_de_munca, comanda, com, 
		cod_condens, condensat
		, (case when contul=cont_debitor then cont_creditor else cont_debitor end) as cont_corespondent
		from #final	

	if object_id('temdb.dbo.#final') is not null drop table #final
	if object_id('temdb.dbo.#ptantet') is not null drop table #ptantet
	if object_id('temdb.dbo.#tmp') is not null drop table #tmp
	if object_id('temdb.dbo.#lm') is not null drop table #lm
