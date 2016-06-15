--***
create procedure tipTVAFacturi @dataJos datetime, @dataSus datetime, @TLI int=null, @parXML xml=null
as
/*
	Aceasta procedura primeste o tabela #facturi_cu_tli (tip,tipf, tert,factura,tipTVA)
	Pe care o altereaza punand in dreptul campului TipTVA tipul corect al TVA-ului Plata Incasare
	ex.
	create table  #facturi_cu_tli (tip varchar(2), tipf char(1), tert varchar(20),factura varchar(20),tip_TVA char(1))
	insert #facturi_cu_tli values('AP','B','11201895','74',' ')
	exec tipTVAFacturi '01/31/2014','01/31/2014'
	select * from #facturi_cu_tli
	drop table #facturi_cu_tli*/
set nocount on
declare @dataTLI datetime, @parXMLFact xml
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
/* Citirea tipului de TVA al unitatii este similara cu cea din procedura inchidTLI */

--	formare TVAPeTerti ca si perioada (atat pt. BD cat si pentru terti).
select row_number() over (partition by tert order by dela) as nr,tert,dela,dela as panala,tip_tva,tipf
into #tvapeterti
from tvapeterti t
where nullif(factura,'') is null	--> se vor lua doar datele tva necesare, adica pentru tert=null si tert existent in #facturi_cu_TLI, altfel simpla inchidere a machetei de pozitii AP poate dura pana la 7 sec, pe Orto de exemplu
	and (tert is null or exists (select 1 from #facturi_cu_TLI f where f.tert=t.tert))
order by dela

update t1 set panala=isnull(dateadd(day,-1,t2.dela),'12/31/2999')
from #tvapeterti t1
left join #tvapeterti t2 on t2.nr=t1.nr+1 and isnull(t1.tert,'')=isnull(t2.tert,'') and t1.tipf=t2.tipf


--	completam in tabela de facturi cu TLI, data si contul facturii din tabela facturi (daca nu s-au completat prin procedura ce apeleaza tipTVAFacturi)
update fTLI 
	set fTLI.Data=(case when fTLI.Data is null then f.data else fTLI.Data end), 
		fTLI.Cont=(case when nullif(fTLI.cont,'') is null then f.Cont_de_tert else fTLI.Cont end)
from #facturi_cu_TLI fTLI
	inner join facturi f on f.subunitate='1' and fTLI.tert=f.tert and fTLI.factura=f.factura and fTLI.tipf=(case when f.tip=0x54 then 'F' else 'B' end)
where fTLI.data is null or nullif(fTLI.cont,'') is null

--	completam printr-un While, data si contul facturii din pFacturi (in loc de fFacturiCen) (doar pentru acele facturi care au data sau contul necompletate - ar trebui sa ajunga aici foarte putine cazuri).
--	am pus mai jos conditia ca tert/factura sa fie completate intrucat am gasit pe BD Elcar ceva DVI-uri fara receptie si in acel caz factura era=''. Si nu mai iesea din bucla.

declare @dinpfacturi bit	--> "dinpfacturi" pentru a se evita apelul recursiv al pFacturi - genereaza eroare datorita tabelelor temporare folosite
set @dinpfacturi=isnull(@parXML.value('(/row/@dinpfacturi)[1]','bit') ,0)
if @dinpfacturi=0
begin
	if (select count(1) from #facturi_cu_TLI where tert<>'' and factura<>'' and data is null and nullif(cont,'') is null)>30
	begin
		raiserror('Exista mai mult de 30 de facturi care nu apar in tabela "facturi"! Dati "Refacere facturi" si reveniti!',16,1)
		return
	end
	while exists (select 1 from #facturi_cu_TLI where tert<>'' and factura<>'' and data is null and nullif(cont,'') is null)
	begin
		if object_id('tempdb..#pfacturi') is not null 
			drop table #pfacturi
		create table #pfacturi (subunitate varchar(9))
		exec CreazaDiezFacturi @numeTabela='#pfacturi'

		declare @tipf char(1), @tert varchar(13), @factura varchar(20)
		select top 1 @tipf=tipf, @tert=tert, @factura=factura
		from #facturi_cu_TLI ftli 
		where tert<>'' and factura<>'' and data is null and nullif(cont,'') is null
	
		truncate table #pfacturi
		set @parXMLFact=(select @tipf as furnbenef, @dataSus as datasus, 1 as cen, rtrim(@tert) as tert, rtrim(@factura) as factura for xml raw)
		exec pFacturi @sesiune=null, @parXML=@parXMLFact
		if (select count(1) from #pfacturi)<1
			delete from #facturi_cu_TLI where tipf=@tipf and tert=@tert and factura=@factura

		update fTLI 
			set fTLI.data=fc.data, fTLI.cont=fc.cont_factura
		from #facturi_cu_TLI ftli 
			inner join #pfacturi fc on fTLI.tipf=(case when fc.tip=0x54 then 'F' else 'B' end) and fTLI.tert=fc.tert and fTLI.factura=fc.factura
			--outer apply (select data, cont_factura from dbo.fFacturiCen(fTLI.tipf, '01/01/1921', @dataSus, fTLI.tert, fTLI.factura, null, null, null, null, null, null) a) fc
	end
end
if object_id ('tempdb..#tmp_tli') is null
	create table #tmp_tli(tip varchar(2),tipf varchar(1),tert varchar(20),factura varchar(20),tip_tva char(1),ranc int)
	
/*Stabilire tip TVA facturi pe tabela temporara - Lasam doar facturile cu TVA la incasare*/
insert into #tmp_tli(tip, tipf, tert, factura, tip_tva, ranc)
select ft.tip,ft.tipf,ft.tert,ft.factura,
	(case	when left(ft.Cont,3) in ('408','418') then 'P' 
			--when ft.tipf='B' then isnull(tvatf.tip_tva,isnull(tvatb.tip_tva,'P'))
			else isnull(tvatf.tip_tva,isnull(tvat.tip_tva,isnull(tvatb.tip_tva,'P'))) end) as tip_tva,
	row_number() over (partition by ft.tipf,ft.tert,ft.factura order by isnull(tvatf.dela,isnull(tvat.dela,isnull(tvatb.dela,'01/01/1901'))) desc) as ranc
from #facturi_cu_TLI ft
outer apply (select top 1 tvatb.tip_tva, tvatb.dela from #TvaPeTerti tvatb where tvatb.tipf='B' and tvatb.tert is null and ft.data between tvatb.dela and tvatb.panala order by tvatb.dela desc) tvatb
-- pentru cei care sunt cu TLI, tipul tertului este dat de o pozitie cu factura = null si tipF='F' (chiar si la avize!)
outer apply (select top 1 tvat.tip_tva, tvat.dela from #TvaPeTerti tvat where tvat.tipf=(case when ft.tipf='B' and isnull(tvatb.tip_tva,'P')='P' then 'B' else 'F' end)
	and tvat.tert=ft.tert and ft.data between tvat.dela and tvat.panala and tvat.tip_tva<>'N' order by tvat.dela desc) tvat
left outer join TvaPeTerti tvatf on tvatf.tipf=ft.tipf and tvatf.Tert=ft.tert and tvatf.factura=ft.factura
where ft.data>'2012-12-31' or ft.tipf='B'


update ftli
set tip_tva=t.tip_tva  -- cei care nu sunt cu TLI nu pot avea facturi emise cu TLI
from #facturi_cu_TLI ftli
inner join #tmp_tli t on ftli.tipf=t.tipf and ftli.tert=t.tert and ftli.factura=t.factura and t.ranc=1


drop table #tvapeterti

--if exists(select 1 from #facturi_cu_TLI where tip_tva='')
--	raiserror('Eroare. Exista facturi cu tip indecis! Luati legatura cu furnizorul aplicatiei!',16,1)