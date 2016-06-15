--***
create procedure rapBorderouCECuri (@sesiune varchar(50)=null, @datajos datetime, @datasus datetime,
		@numar varchar(13)=null, @tert varchar(13)=null, @locm varchar(9)=null, @banca varchar(30)=null, 
		@filtrareScadenta int=0, @datascadJos datetime=null, @datascadSus datetime=null, 
		@ordonare int=1, --1 ordonare pe banca, 2 ordonare pe data
		@parXML xml = null)
as
begin try
	/**	CGplus\Situatii\Plati incasari\Borderou CECuri
	declare @datajos datetime,@datasus datetime,@tert varchar(13),@locm varchar(9)
	select @datajos='2013-12-01 00:00:00',@datasus='2013-12-31 00:00:00',@tert=null,@locm=null
	exec rapBorderouCECuri @datajos=@datajos, @datasus=@datasus
	--*/
	set transaction isolation level read uncommitted
	
	/** pregatirea filtrarii pe locuri de munca */
	declare @subunitate varchar(9), @utilizatorAsis varchar(20), @eLmUtiliz int, @eroare varchar(1000)
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	select @utilizatorAsis=dbo.fIaUtilizator(@sesiune)
	set @eLmUtiliz=dbo.f_areLMFiltru(@utilizatorAsis)
	
	select p.subunitate, p.cont, p.data, p.numar, p.numar_pozitie, p.Plata_incasare, p.Tert, t.Denumire, p.Factura, p.Comanda, p.Suma, p.Valuta, 
		p.Curs_la_valuta_facturii, p.Loc_de_munca, p.detalii.value('(/row/@datascad)[1]','varchar(10)') as data_scadentei, 
		p.detalii.value('(/row/@banca)[1]','varchar(20)') as banca, p.detalii.value('(/row/@contbanca)[1]','varchar(35)') as contbanca, 
		p.detalii.value('(/row/@bancatert)[1]','varchar(20)') as bancatert, p.detalii.value('(/row/@contbctert)[1]','varchar(35)') as contbctert,
		p.detalii.value('(/row/@serieefect)[1]','varchar(20)') as serieefect, p.detalii.value('(/row/@numarefect)[1]','varchar(20)') as numarefect
	from pozplin p
		left outer join conturi c on c.Subunitate=p.Subunitate and c.Cont=p.Cont
		left outer join terti t on t.Subunitate=p.Subunitate and t.Tert=p.Tert
	where p.subunitate=@subunitate and data between @datajos and @datasus 
		and c.Sold_credit=8 and p.Plata_incasare='IB'
		and (@numar is null or p.Numar=@numar)
		and (@tert is null or p.Tert=@tert)
		and (@locm is null or p.Loc_de_munca like @locm+'%')
		and (@filtrareScadenta=0 or p.detalii.value('(/row/@datascad)[1]','varchar(10)') between @datascadJos and @datascadSus)
		and (@banca is null or p.detalii.value('(/row/@banca)[1]','varchar(30)')=@banca)
		and (@eLmUtiliz=0 or exists (select 1 from lmfiltrare lf where lf.utilizator=@utilizatorAsis and p.Loc_de_munca=lf.cod))
	order by p.Subunitate, (case when @ordonare=1 then p.detalii.value('(/row/@banca)[1]','varchar(20)') else convert(char(10),p.data,112) end), p.Tert

end try

begin catch        
	set @eroare=ERROR_MESSAGE()+' (rapBorderouCECuri)'
	raiserror(@eroare, 11, 1)   
end catch 
