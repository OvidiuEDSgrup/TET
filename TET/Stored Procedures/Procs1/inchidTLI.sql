--***
create procedure inchidTLI @dataJos datetime,@dataSus datetime, @lm varchar(20)='', @com varchar(20)='', @indbug varchar(20)=''
as
/*
	exec inchidTLI '07/01/2014','07/31/2014'
*/
if exists(select * from sysobjects where name='inchidTLISP' and type='P')
begin
	exec inchidTLISP @dataJos=@dataJos ,@dataSus=@dataSus , @lm=@lm , @com =@com , @indbug =@indbug 
	return 0
end
set nocount on
declare 
	@cSub varchar(20),@CtTvaNeexPlati varchar(40),@CtTvaNeexIncasari varchar(40),@TLI int,@dataTLI datetime, @cotaTVA int, @parXMLFact xml

select @cSub=val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO'
select @CtTvaNeexPlati=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CNTLIFURN'
if isnull(@CtTvaNeexPlati,'')=''
	set @CtTvaNeexPlati='4428'

select @CtTvaNeexIncasari=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CNTLIBEN'
if isnull(@CtTvaNeexIncasari,'')=''
	set @CtTvaNeexIncasari='4428'
select @cotaTVA=Val_numerica from par where Tip_parametru='GE' and Parametru='COTATVA'

/*Sterg liniile din luna curenta pentru ca altfel ar da efect in Procentul de Tva exigibiliziat pana acum*/
delete from pozplin
	where subunitate=@cSub and data between @datajos and @datasus 
		and Plata_incasare='PC' and cont=@CtTvaNeexPlati and numar like 'IT%'
		and (@lm='' or Loc_de_munca like rtrim(@lm)+'%')

delete from pozplin
	where subunitate=@cSub and data between @datajos and @datasus 
		and Plata_incasare='IC' and cont=@CtTvaNeexIncasari and numar like 'IT%'
		and (@lm='' or Loc_de_munca like rtrim(@lm)+'%')

/*Se aduc datele din pFacturi (in loc de fFacturi) cu parametru sa aduca doar datele din perioada dataJos,dataSus
	Tabela in care vor ajunge aceste date se chema #FacturiDeTratat
	SursaDate poate fi I=Incasare,F=Facturi pe sold
*/
select top 1 @TLI=(case when tip_tva='I' then 1 else 0 end),@dataTLI=dela
	from TvaPeTerti
	where TvaPeTerti.tipf='B' and tert is null and tip_tva='I' and @dataJos>=dbo.BOM(dateadd(day,-90,dela))
	order by dela desc

if @TLI is null
	set @TLI=0

/* Se proceseaza doar plati sau incasari in echivalentul lor (pot fi si CF, CO, ...)*/
/* Se iau cele fara contul de efecte*/
/* se preia in tabela #pfacturi prin procedura pFacturi, in locul functiei fFacturi */
if object_id('tempdb..#docfacturi') is not null drop table #docfacturi
create table #docfacturi (furn_benef char(1))
exec CreazaDiezFacturi @numeTabela='#docfacturi'

set @parXMLFact=(select 'F' as furnbenef, @dataJos as datajos, @dataSus as datasus, 1 as strictperioada, @lm as locm for xml raw)
exec pFacturi @sesiune=null, @parXML=@parXMLFact

select 0x54 as tipf,ft.data,ft.tert,ft.factura,ft.Loc_de_munca as lm,ft.achitat as sumaincpla,'I' as sursadate
	into #FacturiDeTratat
	from #docfacturi ft
	--from dbo.fFacturi('F', @dataJos,@dataSus, null, null, null, 0,0,1, null, null) ft
	left outer join conturi c on c.Subunitate=@cSub and ft.cont_coresp=c.cont
	where abs(achitat)>0.001 and c.sold_credit!='8'

truncate table #docfacturi
set @parXMLFact=(select 'B' as furnbenef, @dataJos as datajos, @dataSus as datasus, 1 as strictperioada, @lm as locm for xml raw)
exec pFacturi @sesiune=null, @parXML=@parXMLFact

insert into #FacturiDeTratat	
	select 0x46,ft.data as data,ft.tert,ft.factura,ft.Loc_de_munca as lm,ft.achitat as sumaincpla,'I' as sursadate
	from #docfacturi ft
	--from dbo.fFacturi('B', @dataJos,@dataSus, null, null, null, 0,0,1, null, null) ft
	left outer join conturi c on c.Subunitate=@cSub and ft.cont_coresp=c.cont
	where abs(ft.achitat)>0.001 and c.sold_credit!='8' and @TLI=1 

/*Pentru efecte luam din pozplin pentru perioada respectiva*/
select p.plata_incasare as tip, p.data, p.Cont_corespondent as Cont, (case when p.plata_incasare='ID' then 0x46 else 0x54 end) as tipf, p.tert, isnull(p.efect,p.numar) as Efect, p.Suma, p.Loc_de_munca as lm 
	into #efAchitate
	from pozplin p 
	inner join conturi contpplin on contpplin.Subunitate=@cSub and contpplin.cont=p.Cont_corespondent and contpplin.sold_credit=8
	where p.subunitate=@cSub and p.plata_incasare in ('PD','ID') and p.data between @datajos and @datasus
--	momentan n-am comentat partea de mai jos (asa cum discutat cu Ghita initial). @TLI va fi 0 daca firma nu a fost niciodata cu TLI		
		and not (@TLI=0 and p.plata_incasare='ID') 
		and (@lm='' or p.Loc_de_munca like rtrim(@lm)+'%')

select p1.Subunitate,p1.cont,p1.tert,p1.Factura,isnull(p1.efect,p1.numar) as Efect,sum(p1.suma) suma,p1.Loc_de_munca as lm
	into #efInitiale
	from pozplin p1 
	inner join conturi contpplin on contpplin.Subunitate=@cSub and contpplin.cont=p1.Cont and contpplin.sold_credit=8
	inner join #efAchitate a on p1.Tert=a.Tert and p1.cont=a.cont and isnull(p1.efect,p1.numar)=a.Efect -- filtrare doar cele atinse in perioada curenta 
	where p1.subunitate=@cSub and p1.plata_incasare in ('PF','IB') 
--	momentan n-am comentat partea de mai jos (asa cum discutat cu Ghita initial). @TLI va fi 0 daca firma nu a fost niciodata cu TLI
		and not (@TLI=0 and p1.plata_incasare='IB') 
		and (@lm='' or p1.Loc_de_munca like rtrim(@lm)+'%')
	group by p1.Subunitate,p1.cont,p1.tert,p1.Factura,p1.Loc_de_munca,isnull(p1.efect,p1.numar)

insert into #FacturiDeTratat
select a.tipf,a.data,a.tert,ei.factura,a.lm,ei.suma*(a.suma/eis.suma) as sumaincpla,'I' as sursadate
	from #efAchitate a 
	inner join #efInitiale ei on a.Tert=ei.Tert and a.cont=ei.cont and a.Efect=ei.Efect
	inner join 
		(select Subunitate,cont,tert,efect, sum(suma) suma
		from #efInitiale 
		group by Subunitate,cont,tert,efect) eis
		on a.Tert=eis.Tert and a.cont=eis.cont and a.Efect=eis.Efect and abs(eis.suma)>=0.01
	where ei.suma<>0

/*Mai inseram in aceasta tabela ca TVA de exigibilizat, liniile din tabela facturi
		legate cu terti ce au tva la incasare a caror scadenta a trecut de 90 de zile si inca se gasesc pe sold.*/
if @TLI=1 and @datasus<='12/31/2013'--Daca suntem TLI ne intereseaza doar Facturile Beneficiar. Incepand cu 01.01.2014, s-a eliminat conditia de 90 de zile
begin
	declare @dataFiltrare datetime
	set @dataFiltrare=dateadd(day,-1,@dataJos)

	truncate table #docfacturi
	set @parXMLFact=(select 'B' as furnbenef, @dataFiltrare as datasus, 0.01 as soldmin, @lm as locm for xml raw)
	exec pFacturi @sesiune=null, @parXML=@parXMLFact

	select f.data as datafact,ft.data,ft.tert,ft.factura,ft.Loc_de_munca as lm,ft.valoare+ft.tva as valoare,ft.achitat as achitat,'F' as sursadate,ft.tva as tva,ft.cont_coresp
		into #FacturiSold90
		from #docfacturi ft
		--from dbo.fFacturi('B', null, @dataFiltrare, null, null, null, 0.01,0,0, null, null) ft
		inner join facturi f on f.tip=0x46 and ft.tert=f.tert and ft.factura=f.factura	--aici lasam join pe facturi caci nu prea se va mai intra prin acest loc
		
		/*Sunt luate in calcul mai sus, deci trebuie scazut soldul facturilor cu ele*/
		--delete ft
		--from #FacturiSold90 ft
		--left outer join conturi c on c.Subunitate=@cSub and ft.cont_coresp=c.cont
		--where abs(ft.achitat)>0.001 and (datediff(day,ft.datafact,ft.data)>90 or c.sold_credit='8')

		/* Deoarece acum iau soldul la inceputul lunii, nu mai trebuie sa sterg pozitii ulterioare dafacat+90, ci vezi mai jos*/
		/* Adun incasari de la inceputul lunii la datafact+90, astfel incat sa obtin soldul la datafact+90*/
	insert #FacturiSold90
		select f.data,ft.data,ft.tert,ft.factura,ft.lm,0,sumaincpla,'F' as sursadate,0,''
		from #FacturiDeTratat ft
		inner join facturi f on f.tip=0x46 and ft.tert=f.tert and ft.factura=f.factura	--aici lasam join pe facturi caci nu prea se va mai intra prin acest loc
		where tipf=0x46 and ft.data<=dateadd(day,90,f.data) -- pot fi probleme la limita (in cea de-a 90-a zi)!
			-- ma intereseaza daca achitarea curenta se refera la o factura pe sold la inceputul lunii, altfel poate fi "oarba" (ex. achitare cu efect in luna trecuta si incasare efect in luna curenta)
			and exists (select 1 from #FacturiSold90 s where ft.tert=s.tert and ft.factura=s.factura)

	insert into #FacturiDeTratat
		select 0x46,dateadd(day,90,datafact) as data,
				tert,factura,max(lm) as lm,sum(valoare-achitat) as sold,'F' as sursadate
		from #FacturiSold90
		where datediff(day,datafact,@dataSus)>=90 and datafact between dateadd(day,-90,@dataJos) and dateadd(day,-90,@dataSus)
		group by tert,factura,datafact
		having abs(sum(valoare-achitat))>0.01
end
	

--Lucian: utilizam procedura tipTVAFacturi (in locul selectului de mai sus) care stabileste tipul de TVA al facturii
select 
	'' as tip,(case when ft.tipf=0x54 then 'F' else 'B' end) tipf,ft.tert,ft.factura,convert(datetime,null) as data, convert(varchar(40),null) as cont,'' as tip_tva
into #facturi_cu_TLI
from #FacturiDeTratat ft
exec tipTVAFacturi @dataJos=@dataJos, @dataSus=@dataSus, @TLI=@TLI

--	stergem facturile beneficiar care au fost inchise dpdv TLI in anul 2013 (la 90 de zile) si au avut incasari dupa 90 de zile de la data facturii. Pt. inchideri din 2013.
delete ft
	from #FacturiDeTratat ft
	inner join #facturi_cu_TLI f on (case ft.tipf when 0x54 then 'F' else 'B' end)=f.tipf and ft.tert=f.tert and ft.factura=f.factura
	where @datasus<='12/31/2013' and ft.tipf= 0x46 and not(datediff(day,f.data,ft.data)<=90)

--	stergem facturile beneficiar care au fost inchise dpdv TLI in anul 2013 (la 90 de zile), dar au ramas pe sold dpdv contabil
delete ft
	from #FacturiDeTratat ft
	inner join #facturi_cu_TLI f on (case ft.tipf when 0x54 then 'F' else 'B' end)=f.tipf and ft.tert=f.tert and ft.factura=f.factura
	where f.tip_tva!='I' or @datasus>='01/01/2014' and ft.tipf= 0x46 and dateadd(day,90,f.data)<='12/31/2013'

--	nu tratam facturile care au fost inchise dpdv TLI intr-o luna anterioara 
--	ex. cazul in care nu s-au instalat versiuni noi pentru renuntarea la 90 de zile si factura a fost inchisa dpdv TLI intr-o luna anterioara lunii incasarii.
if exists (select 1 from SoldFacturiTLI where datalunii<@dataJos)
Begin
	delete ft
	from #FacturiDeTratat ft
		inner join #facturi_cu_TLI f on (case ft.tipf when 0x54 then 'F' else 'B' end)=f.tipf and ft.tert=f.tert and ft.factura=f.factura
	where @datasus>='01/01/2014' and ft.tipf= 0x46 and f.Data<@datajos 
		and not exists (select 1 from SoldFacturiTLI s where s.datalunii=DateADD(day,-1,@datajos) and s.tert=ft.tert and s.tipf='B' and s.factura=ft.factura and s.Sold<>0)
End

select tipf,tert,factura
	into #FacturiDeTratatGrupate
	from #FacturiDeTratat
	group by tipf,tert,factura

select tip,tert,factura,cota_tva,sum(tvad) as tvad,sum(valoare) as valoare, eCuTLI 
	into #facturipecote -- sume pe facturi cu TVA deductibil pe cote
	from	--Aici vine un UNION dintre pozdoc si pozadoc si factimpl
	(select (case when p.tip in ('AP','AS') then 0x46 else 0x54 end) as tip,p.tert,p.Factura,p.cota_tva,tva_deductibil as tvad,
		round(p.cantitate*(case when p.tip in ('AP','AS') then p.Pret_vanzare -- avize
				else round(p.pret_valuta*(case when valuta='' or p.tip='RP' then 1 else p.curs end)*(1+p.discount/100),5) end),2) -- receptii
			+p.TVA_deductibil as valoare, 
		(case when p.procent_vama=0 and p.cota_tva>0 then 1 else 0 end) as eCuTLI 
	from #FacturiDeTratatGrupate ft
	inner join pozdoc p on p.Subunitate=@cSub and p.tip in ('RM','RS','RP','AP','AS') and p.tert=ft.tert and p.Factura=ft.factura
	where ft.tipf=(case when p.tip in ('AP','AS') then 0x46 else 0x54 end) 
	union all
	select (case when p.tip in ('FB','IF') then 0x46 else 0x54 end) as tip,p.tert,(case when p.tip in ('FB','IF') then p.factura_stinga else p.Factura_dreapta end),p.tva11,p.tva22 as tvad,
		p.suma+p.TVA22 as valoare, 
		(case when p.stare=0 and p.tva11>0 then 1 else 0 end) as eCuTLI 
	from #FacturiDeTratatGrupate ft
	inner join pozadoc p on p.Subunitate=@cSub and p.tip in ('FF','FB','IF','SF') and p.tert=ft.tert and ft.factura=(case when p.tip in ('FB','IF') then p.Factura_stinga else p.Factura_dreapta end)
	where ft.tipf=(case when p.tip in ('FB','IF') then 0x46 else 0x54 end) --and valuta=''
	) fpecote
	group by tip,tert,factura,cota_tva, eCuTLI

delete #facturipecote where tvad=0 and valoare=0

-- daca am factura la implementare si nu o am pe cote din documente sa o iau din factimpl:
insert #facturipecote -- sume pe facturi cu TVA deductibil pe cote
	select p.tip,p.tert,p.factura,@cotaTVA,p.tva_22 as tvad,p.Valoare+p.TVA_22 as valoare, 1
	from #FacturiDeTratatGrupate ft
	inner join factimpl p on p.Subunitate=@cSub and p.tert=ft.tert and ft.factura=p.Factura and ft.tipf=p.tip
	where not exists (select 1 from #facturipecote fp where fp.tip=p.tip and fp.tert=p.tert and fp.factura=p.factura)

select ft.tipf,ft.data,ft.tert,ft.factura,
	(case 
		--Din tabela FACTURI fara nicio cota sau valoarea facturii este aproximativ valoarea pe cote:
		when fd.factura is null or abs(fd.valoare - (f.Valoare+f.TVA_22+f.tva_11))<0.02 then ft.sumaincpla*(f.tva_22+f.tva_11)/(f.Valoare+f.tva_22+f.tva_11) 
		-- Ponderarea sumei de TVA pe cote: 
		else ft.sumaincpla*fd.tvad/fg.Valoare  
	end) as sumaTVA,
	(case when fd.factura is not null then fd.cota_tva/100.00
		when (f.tva_22+f.tva_11)/(f.Valoare+f.tva_22+f.tva_11)>0.20 then 0.24
		when (f.tva_22+f.tva_11)/(f.Valoare+f.tva_22+f.tva_11) between 0.07 and 0.11 then 0.09
		when (f.tva_22+f.tva_11)/(f.Valoare+f.tva_22+f.tva_11) between 0.2 and 0.06 then 0.05
		else 0.24 end) as cotatva, 
	(case 
		--Din tabela FACTURI fara nicio cota sau valoarea facturii este aproximativ valoarea pe cote:
		when fd.factura is null or abs(fd.valoare - (f.Valoare+f.TVA_22+f.tva_11))<0.02 
		/*	Am tratat mai jos cazul in care in #facturipecote sunt 2 pozitii: una cu TLI si cealalta fara TLI. In acest caz sa nu aduca din valoarea incasata din facturi ci sa calculeze valoarea incasata ponderat */
			and not exists (select 1 from #facturipecote fd1 where fd1.tip=fd.tip and fd1.tert=fd.tert and fd1.factura=fd.factura and fd1.eCuTLI<>fd.eCuTLI)
		then ft.sumaincpla 
		-- Ponderarea sumei achitate pe cote: 
		else ft.sumaincpla*fd.valoare/fg.Valoare 
	end) as sumaincpla,
		isnull(nullif(ft.lm,''),(case when isnull(f.Loc_de_munca,'')='' then isnull(@lm,'') else f.Loc_de_munca end)) as lm, 
		(case when isnull(left(f.Comanda,20),'')='' then isnull(@com,'') else left(f.Comanda,20) end) as com, 
		(case when isnull(substring(f.Comanda,21,20),'')='' then isnull(@indbug,'') else substring(f.Comanda,21,20) end) as indbug
into #platidegenerat
from #FacturiDeTratat ft
inner join facturi f on ft.tipf=f.tip and ft.tert=f.tert and ft.factura=f.Factura
left outer join #facturipecote fd on ft.tipf=fd.tip and ft.tert=fd.tert and ft.factura=fd.Factura
left outer join 
	(select tip,tert,factura,sum(valoare) as valoare from #facturipecote group by tip,tert,factura) fg on ft.tipf=fg.tip and ft.tert=fg.tert and ft.factura=fg.Factura
where abs(f.valoare+f.tva_22+f.tva_11)>0.01 and f.data>'2012-12-31'
	and isnull(fd.eCuTLI,1)=1 and abs(isnull(fd.valoare,f.valoare))>0  
	-- nu se iau in calcul pozitii nedeductibile sau cu cota TVA=0. Pus cu isnull deoarece facturile la implementare nu exista in #facturipecote deci nu se pot face filtre pe #fd

if exists(select * from sysobjects where name='inchidTLISP2' and type='P')
begin
	exec inchidTLISP2 @dataJos=@dataJos ,@dataSus=@dataSus , @lm=@lm , @com =@com , @indbug =@indbug 
end

declare @px xml
set @px=(
select convert(varchar(10),pgniv1.Data,101) as '@data',(case when tipf=0x54 then @CtTvaNeexPlati else @CtTvaNeexIncasari end) as '@cont',
	(select 'ITVA'+right(replace(convert(char(10),pgniv1.Data,102),'.',''),4) as '@numar',
		(case when tipf=0x54 then 'PC' else 'IC' end) as '@subtip',
		rtrim(pgniv2.lm) as '@lm', rtrim(pgniv2.com) as '@comanda', rtrim(pgniv2.indbug) as '@indbug', 
		rtrim(pgniv2.tert) as '@tert',rtrim(pgniv2.factura) as '@factura',
		convert(decimal(12,2),pgniv2.sumaTVA) as '@suma',
		convert(decimal(12,2),pgniv2.sumaTVA) as '@sumatva',
		convert(decimal(12,2),pgniv2.cotatva*100) as '@cotatva',
		convert(decimal(12,2),pgniv2.sumaincpla) as '@curs', -- tin aici suma achitata totala 
		(case when tipf=0x54 then @CtTvaNeexPlati else @CtTvaNeexIncasari end) as '@contcorespondent',
			(select convert(decimal(12,2),pgniv2.sumaincpla) as valachitat for xml raw, type) as detalii
		from #platidegenerat pgniv2
			where pgniv2.data=pgniv1.data and pgniv2.tipf=pgniv1.tipf and abs(pgniv2.sumaTVA)>=0.01
	for xml path,type
	)
from #platidegenerat pgniv1
where abs(sumaTVA)>=0.01
group by data,tipf
for xml path,type,root('Date'))

exec wScriuPlin '',@px 

drop table #facturi_cu_TLI
drop table #platidegenerat
if object_id ('tempdb..#efInitiale') is not null drop table #efInitiale
if object_id ('tempdb..#efAchitate') is not null drop table #efAchitate
if object_id ('tempdb..#FacturiDeTratat') is not null drop table #FacturiDeTratat
if object_id ('tempdb..#FacturiSold90') is not null drop table #FacturiSold90

/*Pentru salvare sold apelez rapJurnalTvaLaIncasare*/
exec rapJurnalTvaLaIncasare @cFurnBenef='F', @dataJos=@dataJos, @dataSus=@dataSus, @tert=null, @factura=null,@loc_de_munca=@lm,
	@cote_tva='' ,@ordonare=1,@dinInchidTLI=1

if @tli=1 /*Pentru Beneficiari rulam procedura doar daca suntem noi insine cu TLI*/
	exec rapJurnalTvaLaIncasare @cFurnBenef='B', @dataJos=@dataJos, @dataSus=@dataSus, @tert=null, @factura=null,@loc_de_munca=@lm,
		@cote_tva='' ,@ordonare=1,@dinInchidTLI=1
