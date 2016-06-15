
create procedure wOPVerificareDifD394_p @sesiune varchar(50), @parXML xml
as

-- Populare #D394det
declare
	@numedecl varchar(100), @prendecl varchar(100), @functiedecl varchar(100), @tipdecl varchar(1), @datajos datetime, @datasus datetime, 
	@an int, @luna int

select
	@numedecl = 'Operatie',
	@prendecl = 'ASW',
	@functiedecl = 'OP',
	@tipdecl = isnull(@parXML.value('(/row/@tipdecl)[1]','varchar(1)'),'L'),
	@luna = isnull(@parXML.value('(/row/@luna)[1]','int'),datepart(mm,getdate())),
	@an = isnull(@parXML.value('(/row/@an)[1]','int'),datepart(yy,getdate()))

-- Populare #D394det
select
	@datajos = dbo.bom(convert(varchar(10),convert(varchar(4),@an) + '-' + convert(varchar(2),@luna) + '-01',101)),
	@datasus = dbo.eom(convert(varchar(10),convert(varchar(4),@an) + '-' + convert(varchar(2),@luna) + '-01',101))

if object_id('tempdb..#D394det') is not null drop table #D394det
create table #D394det (subunitate varchar(20))
		exec Declaratia39x_tabela

exec Declaratia394 @sesiune=@sesiune,@data=@datasus,@nume_declar=@numedecl,@prenume_declar=@prendecl,@functie_declar=@functiedecl,@caleFisier='',
	@dinRia=1,@tip_D394=@tipdecl, @genRaport=2

-- Populare #jtvavanz
if object_id('tempdb..#jtvavanz') is not null drop table #jtvavanz
create table #jtvavanz (numar char(20))
	exec CreazaDiezTVA '#jtvavanz'

exec rapJurnalTVAVanzari  @sesiune=@sesiune, @DataJ=@datajos, @DataS=@datasus, @RecalcBaza=0, @nTVAex=0	
	,@Provenienta='', @OrdDataDoc=0, @OrdDenTert=1, @DifIgnor=0.5, @TipTvaTert=0	
	,@ContF=null, @LM=null, @LMExcep=0, @ContCor=null, @ContFExcep=0	
	,@Tert=null, @Factura=null, @cotatvaptfiltr=null, @Gest=null, @Jurnal=null
	,@FFFBTVA0=0, @SiFactAnul=0, @TVAAlteCont=0, @DVITertExt=0		
	,@DetalDoc=0, @CtVenScDed='', @CtPIScDed='', @CtCorespNeimpoz=''	
	,@parXML=null

-- Populare #tvacump
if object_id('tempdb..#jtvacump') is not null drop table #jtvacump
create table #jtvacump (numar char(20))
	exec CreazaDiezTVA '#jtvacump'

exec rapJurnalTVACumparari 
		@sesiune=@sesiune, @DataJ=@datajos, @DataS=@datasus
		,@nTVAex=0, @FFFBTVA0='2', @SFTVA0='2', @OrdDataDoc=0, @Provenienta='', @DifIgnor=0.5
		,@UnifFact=0, @nTVAneded=0, @cotatvaptfiltr=null
		,@ContF=null, @LM =null, @ContCor=null, @Tert=null, @Factura=null
		,@marcaj=0, @DVITertExt=0, @RPTVACompPeRM=0, @Gest=null, @LMExcep=0, @Jurnal=null, @RecalcBaza=0
		,@TVAAlteCont=0, @OrdDenTert=0, @DetalDoc=0, @TipTvaTert=0, @parXML=''

-- Creare tabel pentru datele din grid
declare @tabel_grid table(tert varchar(13), suma_D394 float, suma_jurnal float, diferenta float, vanzcump varchar(1))

insert into @tabel_grid(tert,suma_D394,suma_jurnal,diferenta,vanzcump)
select coalesce(d.tert,j.tert), isnull(d.suma,0),isnull(j.suma,0),abs(isnull(d.suma,0)-isnull(j.suma,0)),'V'
from
	(select tert, sum(valoare_factura+tva) suma
	from #d394det
	where vanzcump='V'
	group by tert) d
full outer join
	(select cod_tert tert, sum(total) as suma
	from #jtvavanz
	group by cod_tert) j
on d.tert=j.tert

insert into @tabel_grid(tert,suma_D394,suma_jurnal,diferenta,vanzcump)
select coalesce(d.tert,j.tert), isnull(d.suma,0),isnull(j.suma,0),abs(isnull(d.suma,0)-isnull(j.suma,0)),'C'
from
	(select tert, sum(valoare_factura+tva) suma
	from #d394det
	where vanzcump='C'
	group by tert) d
full outer join
	(select cod_tert tert, sum(total) as suma
	from #jtvacump
	group by cod_tert) j
on d.tert=j.tert

select (
	select rtrim(coalesce(t.Denumire,g.tert)) as tert, rtrim(g.tert) as cod_tert, convert(decimal(17,2),g.suma_D394) as suma_d394, 
		convert(decimal(17,2),g.suma_jurnal) as suma_jurnal, convert(decimal(17,2),g.diferenta) as diferenta, g.vanzcump as vanzcump
	from @tabel_grid g
	left join terti t on g.tert=t.tert
	where convert(decimal(17,2),g.diferenta)<>0
	order by t.denumire, g.vanzcump
	for xml raw, type
) for xml path('DateGrid'),root('Mesaje')
