create procedure rapFormChitanta (@sesiune varchar(50), @cont varchar(20)=null, @data datetime=null, 
	@numar_pozitie varchar(20)=null, @numar varchar(20)=null, @nrExemplare int=2, @parXML xml,
	@numeTabelTemp varchar(100)=null output)
as

if object_id('tempdb..#rapFormChitanta') is not null
	drop table #rapFormChitanta

set transaction isolation level read uncommitted
declare @subunitate varchar(20), --@sesiune varchar(50), @tip varchar(2), @numar varchar(20), @data datetime,
		@utilizatorASiS varchar(50), @capitalSocial varchar(20), @numeFirma varchar(200), @OrdReg varchar(100), @CUI varchar(100), 
		@AdresaFirma varchar(500), @Judet varchar(100), @contBanca varchar(100), @banca varchar(100),
		@facturi varchar(2000), @cate_facturi int, @comandaSQL nvarchar(max),
		@contF varchar(20), @dataF datetime, @numarF varchar(20), @tert varchar(50), @idpozplin int

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output

if len(@numeTabelTemp) > 0 --## nu se poate trimite in URL 
		set @numeTabelTemp = '##' + @numeTabelTemp
	
if exists (select * from tempdb.sys.objects where name = @numeTabelTemp)
begin 
	set @comandaSQL = 'select @parXML = convert(xml, parXML) from ' + @numeTabelTemp + '
	--drop table ' + @numeTabelTemp
	exec sp_executesql @statement = @comandaSQL, @params = N'@parXML as xml output', @parXML = @parXML output
end

begin try
if exists (select 1 from sysobjects o where o.name='rapFormChitantaSP')
begin
	exec rapFormChitantaSP @sesiune=@sesiune, @cont=@cont, @data=@data, @numar_pozitie=@numar_pozitie, @numar=@numar, @nrExemplare=@nrExemplare, @parXML=@parXML
	return
end

if (@nrExemplare>4) set @nrExemplare=4

select	@contF = @parXML.value('(/row/@cont)[1]','varchar(20)'),
		@dataF = @parXML.value('(/row/@data)[1]','datetime'),
		@numar_pozitie = isnull(@numar_pozitie,@parXML.value('(/row/row/@numar_pozitie)[1]','varchar(20)')),
		@idPozPlin = isnull(@idPozPlin,@parXML.value('(/row/row/@idPozPlin)[1]','int')),
		@numarF = isnull(@parXML.value('(/row/row/@numar)[1]','varchar(20)'), ''),
		@nrExemplare = isnull(@nrExemplare,@parXML.value('(/row/@nrExemplare)[1]','int')),
		@tert=''

select	@subunitate=(case when parametru='SUBPRO' then rtrim(val_alfanumerica) else @subunitate end),
		@numeFirma=(case when parametru='NUME' then rtrim(val_alfanumerica) else @numeFirma end),
		@capitalSocial=(case when parametru='CAPITALS' then rtrim(val_alfanumerica) else @capitalSocial end),
		@OrdReg=(case when parametru='ORDREG' then rtrim(val_alfanumerica) else @OrdReg end),
		@CUI=(case when parametru='CODFISC' then rtrim(val_alfanumerica) else @CUI end),
		@AdresaFirma=(case when parametru='ADRESA' then rtrim(val_alfanumerica) else @AdresaFirma end),
		@Judet=(case when parametru='JUDET' then rtrim(val_alfanumerica) else @Judet end),
		@contBanca=(case when parametru='CONTBC' then rtrim(val_alfanumerica) else @contBanca end),
		@banca=(case when parametru='BANCA' then rtrim(val_alfanumerica) else @banca end)
from par
where Tip_parametru='GE' and Parametru in ('SUBPRO','NUME','CAPITALS','ORDREG','CODFISC','ADRESA','JUDET','CONTBC','BANCA')
-- luare facturi:

if @numarF = ''
	raiserror('Formularul trebuie apelat pentru o singura pozitie, nu din antet!', 16, 1)

select @tert=tert
from pozplin p
where p.idPozPlin=@idPozPlin

select @facturi=null, @cate_facturi=0
select @facturi=isnull(@facturi,'')+rtrim(isnull(p.factura,''))+isnull(' din '+convert(varchar(20),max(f.data),103),'') + ', ',
		@cate_facturi=@cate_facturi+1
from pozplin p 
left join facturi f on f.Factura=p.factura
where p.Subunitate=@subunitate 
and p.Cont=@contF 
and p.data=@dataF 
and p.numar=@numarF
--and p.numar_pozitie=@numar_pozitie 
and (@tert='' or p.tert=@tert)
group by p.factura, f.Data

select @facturi = left(@facturi, len(@facturi) - 1)
declare @nr int
set @nr=0
declare @numarator table(nr int)
while (@nr<@nrExemplare)
begin
	set @nr=@nr+1
	insert into @numarator values (@nr)
end

select 
		row_number() over (partition by 1 order by @numeFirma) as nrcrt,
		@numeFirma FIRMA, 
		@judet JUDET,	
		@AdresaFirma ADRESA,
		@contBanca CONTBC,
		@banca BANCA,
		@CUI CUI,
		@OrdReg ORDREG,
		@capitalSocial CAPITALS,
		max(rtrim(t.Denumire)) denTert,
		max(rtrim(t.Adresa)) adresaTert,
		rtrim(p.Numar) nrchit,
		p.data,
		sum(p.Suma) suma,
		dbo.Nr2Text(sum(p.suma)) as sumaStr,
		'c. v. fact. ' CE,
		--rtrim(max(p.Factura))+' din '+(select convert(varchar(20),max(f.data),103) data from facturi f where f.Factura=max(p.factura))
		@facturi
		factura,
		max(isnull(rtrim(l.oras), rtrim(t.Localitate))) as localitate,
		max(isnull(rtrim(j.denumire), rtrim(t.Judet))) as judetTert,
		max(rtrim(t.Cod_fiscal)) cuiTert,
		(select max(rtrim(BANCA3)) from INFOTERT WHERE max(t.Tert)=INFOTERT.TERT AND infotert.Subunitate=@subunitate 
				and infotert.identificator='') as bancaTert,
		/*floor((--row_number() over (partition by nr.nr order by p.cont, p.data, p.numar)*10+
		@cate_facturi)/10)*/
		floor(--(nr*@cate_facturi)/29
			(nr*(14+@cate_facturi))/60
		) as nr
	into #rapFormChitanta
FROM @numarator nr,pozplin p
inner join terti t on p.Tert=t.Tert
left join Localitati l on l.cod_oras = t.Localitate
left join Judete j on j.cod_judet = t.Judet
where p.Subunitate=@subunitate 
and p.Cont=@contF 
and p.data=@dataF 
and p.numar=@numarF
--and p.numar_pozitie=@numar_pozitie 
and (@tert='' or p.tert=@tert)
GROUP BY p.cont, p.data, p.numar, nr.nr
--order by p.cod

if exists (select 1 from sysobjects o where o.name='rapFormChitantaSP1')
	exec rapFormChitantaSP1 @sesiune=@sesiune, @parXML=@parXML, @cont=@cont, @data=@data, @numar_pozitie=@numar_pozitie, @numar=@numar, @nrExemplare=@nrExemplare


set @comandaSQL = 'select * from #rapFormChitanta'

exec sp_executesql @statement = @comandaSQL

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 16, 1)
end catch
