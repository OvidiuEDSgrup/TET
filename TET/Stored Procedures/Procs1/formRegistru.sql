--***
CREATE PROCEDURE formRegistru @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100)
OUTPUT AS
begin try 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @utilizator varchar(50), @subunitate varchar(20), @cTextSelect nvarchar(max), @unitate varchar(100), @debug bit, @mesaj varchar(1000),
	@cont varchar(20), @data datetime, @tip varchar(2), @eContUtiliz int, @valuta varchar(10), @soldi real, @soldf real
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
-- declaratii variabile
-- citire filtre
	/** Filtre **/
	SET @cont=@parXML.value('(/*/@cont)[1]', 'varchar(20)')
	SET @data=@parXML.value('(/*/@data)[1]', 'datetime')
	SET @tip=@parXML.value('(/*/@tip)[1]', 'varchar(2)')

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT
	IF OBJECT_ID('tempdb..#reg') IS NOT NULL
		DROP TABLE #reg
	
create table #reg(subunitate varchar(10), data datetime, plata_incasare varchar(10),numar varchar(50), explicatii varchar(100), 
					incasari decimal(20,2), plati decimal(20,2), soldi decimal(20,2), soldf decimal(20,2))
					
declare @ContUtiliz table(valoare varchar(200), cod_proprietate varchar(20))

insert into @ContUtiliz(valoare, cod_proprietate)
	select rtrim(valoare),cod_proprietate from fPropUtiliz(@sesiune) where valoare<>'' and cod_proprietate='CONTPLIN'
	
delete c from @ContUtiliz c where exists (select 1 from @ContUtiliz cc		-- eliminare conturi ale caror parinti apar de asemenea
	where c.valoare like cc.valoare+'%' and c.valoare<>cc.valoare)	-- (oricum, situatia tratata aici este contraindicata)
	
set @eContUtiliz=isnull((select max(1) from @ContUtiliz),0)	

set @valuta=''
	if left(@cont,4) in ('5124','5314') -- aici ar trebui dupa proprietatea contului: "In valuta", apoi ce valuta are
		set @valuta='EUR'

	if @valuta<>''

		set @soldi=	isnull(dbo.soldvaluta (@cont, @valuta, @data, 'D'),0)

	else

		set @soldi=	isnull(dbo.soldcont (@cont, @data, 'D'),0)
	
select * from @contutiliz	
					
insert into #reg(subunitate,data, plata_incasare, numar, explicatii, incasari, plati, soldi, soldf)
	select p.subunitate, p.data, p.plata_incasare, p.numar, p.explicatii, 
		(case when left(p.plata_incasare, 1)='I' then (case when @valuta='' then p.suma else p.suma_valuta end) else 0 end) as incasari, 
		(case when left(p.plata_incasare, 1)='P' then (case when @valuta='' then p.suma else p.suma_valuta end) else 0 end) as plati,@soldi,0

	from pozplin p

	where p.subunitate = @subunitate
		and p.data = @data and p.cont = @cont
		and (@eContUtiliz=0 or exists (select 1 from @ContUtiliz u where cont like u.valoare+'%'))

	order by p.data, p.tert, p.factura, p.loc_de_munca
	
	set @soldf=@soldi

	select @soldf=@soldf+isnull(incasari,0)-isnull(plati,0) from #reg

	

	update #reg set soldf=@soldf

	
select
	p.soldi as SOLDI,
	convert(varchar(20),p.data,103) as DATA,
	@unitate as UNITATE,
	rtrim(cont)+' - '+rtrim(c.Denumire_cont) as NUMECONT,
	plata_incasare as TIP,
	p.numar as NUMAR,
	p.explicatii as EXPLICATII,
	p.incasari as INCASARI,
	p.plati as PLATI,
	p.soldf as SOLDF

into #selectMare
from #reg p
left join conturi c on c.cont = @cont

	SET @cTextSelect = '
	SELECT *
	into ' + @numeTabelTemp + '
	from #selectMare
	ORDER BY DATA
	'

	EXEC sp_executesql @statement = @cTextSelect

	/** 
		Daca sunt lucruri specifice de tratat ele vor fi evidentiate in procedura formReceptiiSP1
		prin interventie asupra tabelului @numeTabelTemp (fie alterari ale datelor, fie coloane noi, samd )
	**/
	if exists (select 1 from sysobjects where type='P' and name='formRegistruSP1')
	begin
		exec formRegistruSP1 @sesiune=@sesiune, @parXML=@parXML, @numeTabelTemp=@numeTabelTemp output
	end

	IF @debug = 1
	BEGIN
		SET @cTextSelect = 'select * from ' + @numeTabelTemp

		EXEC sp_executesql @statement = @cTextSelect
	END
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (formRegistru)'
	raiserror(@mesaj, 11, 1)
end catch
