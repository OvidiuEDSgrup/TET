/***--
procedura folosita pentru popularea formului folosit la generarea de receptii din dispozitii.
--***/
CREATE PROCEDURE wOPGenerareReceptie_p @sesiune varchar(50), @parXML xml
AS
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenerareReceptie_pSP')
begin
	declare @returnValue int
	exec @returnValue = wOPGenerareReceptie_pSP @sesiune, @parXML output
	return @returnValue
end

declare @userASiS varchar(50), @mesaj varchar(1000), @iddisp int, @tert varchar(13), @dengestiune varchar(50), @denlm varchar(50)
begin try
	/*Validare utilizator*/
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	/*Preia parametrii XML trimisi */
	select	@iddisp	= @parXML.value('(/*/@iddisp)[1]', 'int'),
		@tert	= @parXML.value('(/*/@tert)[1]', 'varchar(13)')
		
	/*Daca nu s-a selectat nici un document nu se poate efectua operatia. */
	if isnull(@iddisp,0)=0
		raiserror('Va rugam sa selectati documentul pe care doriti sa il modificati.', 11, 1)
	
	/*Daca documentul a fost finalizat nu se mai poate opera */
	if (select max(a.stare) from AntDisp a where a.idDisp = @iddisp) = 'Finalizat'
		raiserror('Documentul a fost deja finalizat, si nu mai poate fi modificat.', 11, 1)
	
	if (select max(a.stare) from AntDisp a where a.idDisp = @iddisp) <> 'scanata '
		raiserror('Aceasta dispozitie nu a fost scanata!.', 11, 1)
	
	set @parXML.modify ('insert attribute cu_inserare_lipsa {"1"} into (/row/detalii/row)[1]') 
	--set @parXML.modify ('insert attribute tert {sql:variable("@tert")} into (/row/detalii/row)[1]')

	-- trimit parXML pentru populare
	select @parXML
	
	select	p.idPoz idpoz,
		p.cod cod, 
		'('+p.cod+') '+RTRIM(n.denumire) denumire,
		ltrim(str(p.pret,12,5)) pret,
		LTRIM(str(p.cantitate)) as cantitate,
		ltrim(str(p.cantitate,12,5)) cant_op, 
		ltrim(str(isnull(ps.cant_ok,0)+ISNULL(p.detalii.value('(/row/@cantitate_diferenta)[1]', 'float'),0),12,5)) cant_scan_ok, 
		ltrim(str(isnull(ps.cant_spart,0),12,5)) cant_scan_spart, 
		ltrim(str(isnull(ps.cant_ok,0)+ISNULL(p.detalii.value('(/row/@cantitate_diferenta)[1]', 'float'),0),12,5)) cant_ok_de_scris, 
		ltrim(str(isnull(ps.cant_spart,0),12,5)) cant_sparta_de_scris,
		ltrim(str(isnull(n.Cota_TVA,0))) as cotatva		
	into #pozitii
	from PozDispOp p 
		inner join nomencl n on p.cod=n.cod
		left join (select ps.idPoz, 
						sum((case when ps.tipPozitie='cantOk' then ps.cantitate else 0 end)) as cant_ok,
						sum((case when ps.tipPozitie='cantSp' then ps.cantitate else 0 end)) as cant_spart 
					from PozDispScan ps, PozDispOp po 
					where idDisp=@iddisp and ps.idPoz=po.idPoz
					group by ps.idPoz) ps 
			on ps.idpoz=p.idpoz
	where p.idDisp=@iddisp
	
	declare @lista_categpret int
	set @lista_categpret=(case when exists (select 1 from fPropUtiliz(@sesiune) where cod_proprietate='CATEGPRET' and valoare<>'')then 1 else 0 end)
	

	/*Cristy a spus sa nu tratez deocamdata cazul in care sunt mai multe categorii de preturi pe un produs*/
	/*Luare date necesare pentru stabilire pret vanzare*/
	select poz.idpoz, 
		rtrim(p.Cod_produs)as cod, 
		rtrim(categorie) as catpret,
		rtrim(cp.Denumire) as 'dencategpret',
		rtrim(p.tip_pret) as tippret,
		dtp.denumire as dentippret,
		convert(char(10),data_inferioara,101) as data_inferioara,
		convert(char(10),data_superioara,101) as data_superioara,
		convert(decimal(12,5),Pret_vanzare) as pret_vanzare,
		convert(decimal(12,5),Pret_cu_amanuntul) as pret_cu_amanuntul,
		rank() over (partition by poz.idpoz order by cp.categorie, data_inferioara desc) as ranc
	into #preturi
	from preturi p
		inner join #pozitii poz on poz.cod=p.Cod_produs
		left outer join categpret cp on p.UM=cp.Categorie
		inner join dbo.fTipPret() dtp on p.tip_pret=dtp.tipPret
		left outer join fPropUtiliz(@sesiune) fp on cod_proprietate='CATEGPRET' and categorie=fp.valoare
	where (@lista_categpret=0 OR fp.valoare is not null)
		and getdate() between data_inferioara and data_superioara
		and isnull(cp.Categorie,'')<>'' 
	
	delete from #preturi where ranc>1	
	
	declare @categorie_pret_dacaNULL int
	set @categorie_pret_dacaNULL= (select top 1 c.Categorie from categpret c where c.Tip_categorie=1 
										and exists(select 1 from preturi pr where pr.um=c.Categorie and YEAR(pr.Data_superioara)=2999) order by c.Categorie )
	-- inserez toate codurile operate.
	-- NU ESTE TRATAT CAZUL IN CARE ESTE UN COD CU MAI MULTE PRETURI SAU APARE DE MAI MULTE ORI PE O DISPOZITIE
	select 
		(select 
			ROW_NUMBER() over (order by po.idpoz) as nrcrt,
			po.idPoz idpoz,
			po.cod cod, 
			po.denumire denumire,
			ltrim(str(po.pret,12,2)) pret,
			LTRIM(str(po.cantitate)) as cantitate,
			ltrim(str(po.cant_op,12,2)) cant_op, 
			ltrim(str(po.cant_scan_ok,12,2)) cant_scan_ok, 
			ltrim(str(isnull(po.cant_scan_spart,0),12,2)) cant_scan_spart, 
			ltrim(str(po.cant_ok_de_scris,12,2)) cant_ok_de_scris, 
			ltrim(str(isnull(po.cant_sparta_de_scris,0),12,2)) cant_sparta_de_scris,
			--date necesare pentru stabilire pret vanzare
			isnull(po.cotatva,0) as cotatva,
			isnull(pr.pret_vanzare,0) as pretvanzare,
			isnull(pr.pret_cu_amanuntul,0) as pretamanunt,
			convert(decimal(12,2),po.pret) as pretstoc,
			convert(decimal(12,2),round((pret_cu_amanuntul/(1.00+po.cotatva/100)-po.pret)/po.pret*100,2)) as adaos,
			isnull(pr.catpret,@categorie_pret_dacaNULL) as categpret
		from #pozitii po
			left join #preturi pr on pr.idpoz=po.idpoz and pr.cod=po.cod 
		for xml raw,type)
	FOR XML path('DateGrid'), root('Mesaje')
	
	select 1 areDetaliiXml for xml raw, root('Mesaje')
end try
begin catch
	set @mesaj = ERROR_MESSAGE()+' (wOPGenerareReceptie_p)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)

--select * from AntDisp
--select * from PozDispOp
--select * from PozDispscan
--delete from pozdispop where idpoz > 1
--select p.* from pozCon p where tip = 'fc' and subunitate = '1'
--select * from pozdoc where subunitate = '1' and tip = 'rm'
/* <tip()> <contract(numarDocumentSursa identifica unic comanda)> */

/*
insert into pozdispscan
select 2, 'cantOk','','1001', 5, '', 'mitz', getdate(), null
*/
