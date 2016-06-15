
--***
CREATE PROCEDURE wIaPreturi @sesiune VARCHAR(50), @parXML XML
as
/*
	Procedura primiseste parametrii de mai jos (XML) si in functie de o linie din acesti parametrii va oferi preturile
*/

declare @data datetime,@tert varchar(20),@idContract int,@CategPret int,@valuta varchar(20),@gestiune varchar(20),@ora char(8),@subunitate varchar(20),@punctlivrare varchar(20),
	@ComandaLivrare varchar(20)

select top 1 @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'

select @Data = isnull(@parXML.value('(/*/@data)[1]', 'datetime'), getdate()),
	@Tert = isnull(@parXML.value('(/*/@tert)[1]', 'varchar(13)'), ''),
	@punctlivrare = isnull(@parXML.value('(/*/@punctlivrare)[1]', 'varchar(20)'), ''),
	@idContract = isnull(@parXML.value('(/*/@idContract)[1]', 'int'), 0),
	@CategPret= isnull(@parXML.value('(/*/@categoriePret)[1]', 'int'), isnull(@parXML.value('(/*/@categpret)[1]', 'int'), 0)),
	@valuta = isnull(@parXML.value('(/*/@valuta)[1]', 'varchar(20)'), ''),
	@Gestiune = coalesce(nullif(@parXML.value('(/*/@gestprim)[1]', 'varchar(20)'),''),@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'), ''),
	@ComandaLivrare = isnull(@parXML.value('(/*/@comandalivrare)[1]', 'varchar(20)'), '')


	select @ora=replace(convert(char(10),@data,108),':',''),@data=convert(datetime,convert(char(10),@data,101))
/*
	Pasul numarul 1 - poate are o comanda de livrare cu preturi ferme tip = CL
	Tabelelele Contracte, PozContracte
*/

update #preturi
set pret_vanzare=comliv.pret,discount=comliv.discount,valuta=comliv.valuta,calculat=1
from 
	(select pc.cod,max(pc.pret) as pret,max(pc.discount) as discount,max(c.valuta) as valuta
	from Contracte c
	inner join PozContracte pc on c.idContract=pc.idContract
	where c.idContract=@idContract
	group by pc.cod) comliv
	where #preturi.cod=comliv.cod and isnull(calculat,0)=0

/*
	Pasul numarul 2 - ultimul contract pe tert tip = CB Contract Beneficiar
	-> se vor cauta toate contratele valide (pot fi mai multe, in functie de setul de date din #preturi)
	Tabelelele Contracte, PozContracte
*/

update #preturi
set pret_vanzare=c1.pret,discount=c1.discount,valuta=c1.valuta,calculat=1
from
	(	select 
			pc.cod,pc.pret as pret,pc.discount as discount,c.valuta as valuta
		from contracte c 
		INNER JOIN pozcontracte pc on c.idContract=pc.idContract
		INNER JOIN #preturi p on p.cod=pc.cod
		where c.tip='CB' and c.tert=@tert and @data between c.data and ISNULL(c.valabilitate, '01/01/2999')
	) c1
	where 
		#preturi.cod=c1.cod and 
		isnull(calculat,0)=0 

/*
	Pasul numarul 3 - ultimul contract pe tert tip = CB Contract Beneficiar
	Se parcurge acordarea discountuli pe GRUPA-> se vor cauta toate contratele valide (pot fi mai multe, in functie de setul de date din #preturi)
	Tabelelele Contracte, PozContracte
*/
update #preturi
set pret_vanzare=c1.pret,discount=c1.discount,valuta=c1.valuta,calculat=1
from
	(
		select 
			rtrim(n.cod) cod,pc.pret as pret,pc.discount as discount,c.valuta as valuta
		from contracte c 
		inner join pozcontracte pc on c.idContract=pc.idContract
		INNER JOIN grupe g on g.grupa=pc.grupa
		INNER JOIN nomencl n on n.Grupa=pc.grupa
		INNER JOIN #preturi pr on pr.cod=n.cod
		where c.tip='CB' and c.tert=@tert and @data between c.data and ISNULL(c.valabilitate, '01/01/2999') and pc.subtip='DG'
	) c1
	where 
		isnull(calculat,0)=0 and
		#preturi.cod=c1.cod
		

/*Pasul trei si un sfert, la nivel de tert*/
update #preturi
set discount=c1.discount,calculat=1
from
	#preturi 
	inner join (select c.tert,isnull(c.detalii.value('(/row/@discount)[1]', 'decimal(12,2)'), 0) as discount,rank() over (order by c.data desc) as ranc
			from contracte c where c.tip='CB' and c.tert=@tert) c1 on c1.tert=@tert
	where c1.ranc=1 and isnull(calculat,0)=0 and abs(c1.discount)>0.05
	
/*
	Pasul numarul 4 - legacy con si pozcon
*/
--daca se primeste comanda de livrare
if isnull(@ComandaLivrare,'')<>''
begin
	update #preturi
	set pret_vanzare=comliv.pret, discount=comliv.discount, valuta=comliv.valuta, calculat=1
	from 
		(select pc.cod, pc.pret as pret, pc.discount as discount, c.valuta as valuta,rank() over (partition by pc.cod order by c.data desc) as ranc
		from con c
			inner join Pozcon pc on pc.subunitate = c.subunitate
				AND pc.tip = c.tip
				AND pc.contract = c.contract
				AND pc.tert = c.tert
				AND pc.data = c.data
		where c.tip='BK' and c.contract=@ComandaLivrare and c.tert=@Tert) comliv
		where #preturi.cod=comliv.cod and comliv.ranc=1
			and isnull(calculat,0)=0
end

update #preturi
set pret_vanzare=c1.pret,discount=c1.discount,valuta=c1.valuta,calculat=1
from
	(select pc.cod,pc.pret as pret,pc.discount as discount,c.valuta as valuta,rank() over (partition by pc.cod order by c.data desc) as ranc
		from con c 
		inner join pozcon pc on c.subunitate=pc.subunitate and c.tip=pc.tip and c.tert=pc.tert and c.contract=pc.contract
			where c.tip='BF' and c.tert=@tert) c1
	where #preturi.cod=c1.cod and c1.ranc=1
		and isnull(calculat,0)=0

/*Pasul "Se ia din Terti, de pe tert, discountul" */
update #preturi
set discount=terti.disccount_acordat 
	--,calculat=1 /*pretul nu este calculat(pret_vanzare ramane null) */
from terti
	where isnull(calculat,0)=0 and terti.tert=@tert and terti.disccount_acordat>0.05

/*
	Incepem cu tabela de preturi
	Luam @categPret>0 inseamna ca am primit explicit o categorie de pret
	Prima problema e determinarea categoriilor de pret
*/
if isnull(@CategPret,0)=0
	/*Luam categoria de pret din punctul de livrare al tertului*/
	select top 1 @CategPret=sold_ben from infotert it where it.subunitate=@subunitate and tert=@tert and identificator=@punctlivrare and @punctlivrare<>''

if isnull(@CategPret,0)=0
	/*Luam categoria de pret ca si categoria tertului*/
	select top 1 @CategPret=sold_ca_beneficiar from terti t where t.subunitate=@subunitate and t.tert=@tert

if isnull(@CategPret,0)=0
	SELECT @CategPret=valoare
		FROM proprietati
		WHERE tip = 'GESTIUNE'
			AND Cod_proprietate = 'CATEGPRET'
			AND cod = @gestiune

/*Luam categoria de pret ca si proprietate a utilizatorului*/
if isnull(@CategPret,0)=0
begin
	declare @utilizator varchar(100)
	exec wIaUtilizator @sesiune=@sesiune,@utilizator=@utilizator OUTPUT
	
	SELECT @CategPret=min(valoare)
		FROM proprietati
		WHERE tip = 'UTILIZATOR'
			AND Cod_proprietate = 'CATEGPRET'
			AND cod = @utilizator

end

/*
	Se folosesc doar la categorii de pret referite pentru DISCOUNT
		sau
	In cazul in care nu gasesc niciun pret
*/

declare @catBaza varchar(10),@tipCatBaza int
select @catBaza=null
select @catBaza=isnull(categ_referinta,'1'),@tipCatBaza=Tip_categorie
	from categPret where categorie=@categPret
if nullif(@catBaza,0) is null
	set @catBaza='1'
select @tipCatBaza=Tip_categorie
	from categPret where categorie=@catBaza

if @CategPret>0
begin
	declare @tipCategorie char(1),@inValuta int
	select @tipCategorie=null
	select top 1 @tipCategorie=Tip_categorie,@inValuta=categpret.In_valuta
		from categPret where categorie=@categPret
	
	select p1.cod_produs as cod,isnull(p1.umprodus,'') as umprodus,p1.Pret_vanzare,p1.pret_cu_amanuntul,
	rank() over (partition by p1.cod_produs,isnull(p1.umprodus,'') order by p1.tip_pret desc,p1.data_inferioara	desc) as ranc,
	(case when (p1.tip_pret in ('2','9') and @data between p1.Data_inferioara and p1.Data_superioara) or
						(p1.tip_pret='3' and @data between p1.Data_inferioara and p1.Data_superioara and @ora between p1.ora_inferioara and p1.ora_superioara)
		then 1 
		else 0 
		end) as inPromotie
	into #prCat
		from preturi p1
		inner join #preturi pc on p1.cod_produs=pc.cod and isnull(p1.umprodus,'')=isnull(pc.umprodus,'')
		where p1.um=@categPret and p1.tip_pret in ('1','2','3','9')
			and ((p1.tip_pret in ('1','2','9') and @data between p1.Data_inferioara and p1.Data_superioara) or
					(p1.tip_pret='3' and @data between p1.Data_inferioara and p1.Data_superioara and @ora between p1.ora_inferioara and p1.ora_superioara))

	delete from #prCat where ranc>2
	
	if @tipCategorie='3' --Discount
		update p set discount=pcat.pret_vanzare,calculat=1,inpromotie=pcat.inpromotie
		from #preturi p,#prCat pcat where p.cod=pcat.cod and isnull(p.umprodus,'')=isnull(pcat.umprodus,'') and pcat.ranc=1
		and isnull(calculat,0)=0

	if @tipCategorie='2' --Pret cu amanuntul
		update p set pret_amanunt=pcat.pret_cu_amanuntul,pret_amanunt_vechi=pcatold.pret_cu_amanuntul,tipPret='2',calculat=1,inpromotie=pcat.inpromotie
		from #preturi p
		inner join #prCat pcat on p.cod=pcat.cod and isnull(p.umprodus,'')=isnull(pcat.umprodus,'') and pcat.ranc=1
		left join #prCat pcatold on p.cod=pcatold.cod and isnull(p.umprodus,'')=isnull(pcatold.umprodus,'') and pcatold.ranc=2
		where isnull(calculat,0)=0

	if @tipCategorie='1' --Pret vanzare
		update p set pret_vanzare=pcat.pret_vanzare,pret_vanzare_vechi=pcatold.pret_vanzare,calculat=1,inpromotie=pcat.inpromotie
		from #preturi p
		inner join #prCat pcat on p.cod=pcat.cod and isnull(p.umprodus,'')=isnull(pcat.umprodus,'') and pcat.ranc=1
		left join #prCat pcatold on p.cod=pcatold.cod and isnull(p.umprodus,'')=isnull(pcatold.umprodus,'') and pcatold.ranc=2
		and isnull(calculat,0)=0

	if @inValuta=1 and @valuta=''/*Daca preturile sunt in valuta*/
		update #preturi set valuta=nomencl.Valuta
		from nomencl where #preturi.cod=nomencl.cod 

	drop table #prCat
end

select pr.cod_produs as cod,pr.Pret_vanzare,pr.pret_cu_amanuntul,
rank() over (partition by pr.cod_produs,isnull(pr.umprodus,'') order by pr.tip_pret desc,pr.data_inferioara desc) as ranc,
(case when (pr.tip_pret in ('2','9') and @data between pr.Data_inferioara and pr.Data_superioara) or
				(pr.tip_pret='3' and @data between pr.Data_inferioara and pr.Data_superioara and @ora between pr.ora_inferioara and pr.ora_superioara)
		then 1 
		else 0
		end) as inPromotie
into #prBaza
from preturi pr
inner join #preturi pb on pr.cod_produs=pb.cod and isnull(pr.umprodus,'')=isnull(pb.umprodus,'')
where pr.um=@catBaza and pr.tip_pret in ('1','2','3','9')
	and ((pr.tip_pret in ('1','2','9') and @data between pr.Data_inferioara and pr.Data_superioara) or
			(pr.tip_pret='3' and @data between pr.Data_inferioara and pr.Data_superioara and @ora between pr.ora_inferioara and pr.ora_superioara))

delete from #prBaza where ranc>2
/*
	La ultimele update-uri (pret de baza) nu mai conteaza asa de mult daca este calculat sau nu
	Tot ce are pret = 0 (fie vanzare fie cu amanuntul) va fi adus din CatBaza
*/
if @tipCatBaza='2' --Pret cu amanuntul
	update p set pret_amanunt= pcat.Pret_cu_amanuntul,tipPret='2',calculat=1,pret_amanunt_vechi= pcatold.Pret_cu_amanuntul,inpromotie=pcat.inpromotie
	from #preturi p
	inner join #prBaza pcat on p.cod=pcat.cod and pcat.ranc=1
	left join #prBaza pcatold on p.cod=pcatold.cod and pcatold.ranc=2
	where isnull(p.pret_amanunt,0)=0 and isnull(p.pret_vanzare,0)=0

if @tipCatBaza='1' --Pret vanzare
	update p set pret_vanzare=pcat.pret_vanzare,calculat=1,pret_vanzare_vechi=pcatold.Pret_vanzare,inpromotie=pcat.inpromotie
	from #preturi p
	inner join #prBaza pcat on p.cod=pcat.cod and pcat.ranc=1
	left join #prBaza pcatold on p.cod=pcatold.cod and pcatold.ranc=1
	where isnull(p.pret_amanunt,0)=0 and isnull(p.pret_vanzare,0)=0


/*Pret vanzare din pret_cu_amanuntul*/
update p set 
	p.pret_vanzare=p.pret_amanunt/(1.00+n.cota_tva/100.00),
	p.pret_vanzare_vechi=p.pret_amanunt_vechi/(1.00+n.cota_tva/100.00)
from #preturi p,nomencl n 
	where p.cod=n.cod
	and isnull(tipPret,'1')='2'

/*Pret_cu_amanuntul din pret_vanzare*/
update p set 
	--p.pret_amanunt=p.pret_vanzare*(1.00+n.cota_tva/100.00)
	p.pret_amanunt=CEILING(p.pret_vanzare*(1.00+n.cota_tva/100.00)*100)/100,
	p.pret_amanunt_vechi=CEILING(p.pret_vanzare_vechi*(1.00+n.cota_tva/100.00)*100)/100
from #preturi p,nomencl n 
	where p.cod=n.cod
	and isnull(tipPret,'1')='1'

/*Aplicam discountul la preturi*/
update #preturi set 
	pret_vanzare_discountat=pret_vanzare*(1.00-isnull(discount,0)/100),pret_amanunt_discountat=pret_amanunt*(1-isnull(discount,0)/100)

if @valuta='' and exists(select valuta from #preturi where valuta!='') /*Cautam cursuri*/
begin
	select p.valuta,c.curs
	into #valute
		from #preturi p
		cross apply (select top 1 curs from curs where valuta=p.valuta and data<=@data order by data desc) c

	update #preturi
		set pret_vanzare=pret_vanzare*isnull(#valute.curs,1),pret_amanunt=pret_amanunt*isnull(#valute.curs,1),curs=isnull(#valute.curs,1)
		from #valute where #preturi.valuta!='' and #preturi.valuta=#valute.valuta
end

if exists(select * from sysobjects where name='wIaPreturiSP2' and type='P')
	exec wIaPreturiSP2 @sesiune=@sesiune, @parXML=@parXML 

